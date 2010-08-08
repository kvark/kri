namespace support.vb

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics

public class Model( kri.res.ILoaderGen[of kri.Entity] ):
	public class Reader:
		public final bin	as IO.BinaryReader
		public final head	as Header
		public final ent	= kri.Entity()
		public def constructor(path as string):
			bin = IO.BinaryReader( IO.File.OpenRead(path) )
			head = Header(self)
		public def finish() as kri.Entity:
			bin.Close()
			return ent
		public def getByte() as byte:
			return bin.ReadByte()
		public def getLong() as long:
			return bin.ReadInt32()
		public def getReal() as single:
			return bin.ReadSingle()
		public def getString() as string:
			size = bin.ReadUInt16()
			return string( bin.ReadChars(size) )
		# using the fact of strict left->right evaluation order
		public def getColor() as Color4:
			return Color4( getReal(), getReal(), getReal(), getReal() )
		public def getVec2() as Vector2:
			return Vector2( getReal(), getReal() )
		public def getVector() as Vector3:
			return Vector3( getReal(), getReal(), getReal() )
		public def getQuat() as Quaternion:
			return Quaternion( getVector(), getReal() )

	[StructLayout(LayoutKind.Sequential)]
	public struct Vertex:
		public pos	as Vector3
		public rot	as Quaternion
		public col	as Color4
		public tc	as Vector2

	public struct Header:
		public sign			as string
		public formatVer	as int
		private unk0		as byte
		private unk1		as (byte)
		public globalScale	as single
		public coordScale	as single
		public coordName	as string
		private unk2		as byte
		private unk3		as ulong

		public def constructor(rd as Reader):
			.sign = string( rd.bin.ReadChars(8) )
			.unk0 = rd.getByte()
			.formatVer = (0,1)[unk0==3]
			.unk1 = rd.bin.ReadBytes( (4,2)[formatVer] )
			.globalScale = rd.getReal()
			.coordScale = rd.getReal()
			.coordName = rd.getString()
			.unk2 = rd.getByte()
			.unk3 = rd.getLong()

	public static final Signature	= 'B3D 1.1 '
	public final con	as kri.load.Context
	public final res	= kri.res.Manager()
	# unknown vertex attributes
	public final at_un1	= kri.Ant.Inst.slotAttributes.create('un1')
	public final at_un2	= kri.Ant.Inst.slotAttributes.create('un2')
	public final at_un3	= kri.Ant.Inst.slotAttributes.create('un3')

	public def getMaterials(rd as Reader) as bool:
		mid		= rd.getString()
		name	= rd.getString()
		# read mat
		amb		= rd.getColor()
		diff	= rd.getColor()
		emi		= rd.getColor()
		spec	= rd.getColor()
		glossy	= rd.getReal()
		alpha	= rd.getReal()
		assert con
		m = kri.Material(name)
		con.fillMat(m, 1f,diff,spec,glossy)
		m.link()
		rd.ent.tags.Add( kri.TagMat(mat:m) )
		# read the rest
		blend = rd.getString()
		mtype = rd.getString()
		flag1 = rd.getLong()
		flag2 = rd.getLong()
		# unused vars
		mid=''
		amb = emi
		alpha = 0f
		blend = mtype = ''
		flag1 = flag2 = 0
		return true

	public def getTextures(rd as Reader) as bool:
		rd.getByte()	#?
		name	= rd.getString()
		file	= rd.getString()
		wid		= rd.getLong()
		het		= rd.getLong()
		tm = rd.ent.seTag[of kri.TagMat]()
		assert tm
		basic = res.load[of kri.load.image.Basic](file)
		assert basic
		tex = basic.generate()
		assert con
		con.setMatTexture( tm.mat, name, tex )
		wid = het = 0
		return true

	public def getNodes(rd as Reader) as bool:
		rd.getByte()	#?
		name = rd.getString()
		rd.ent.node = kri.Node(name)
		return true

	public def getBones(rd as Reader) as bool:
		name = rd.getString()
		sp = kri.Spatial.Identity
		rd.bin.ReadBytes(2)	#?
		flag = rd.getByte()
		if flag!=0:
			sp.pos = rd.getVector()
			if flag==3: sp.rot = rd.getQuat()
			if flag==2: sp.scale = rd.getReal()	#?
		kri.NodeBone(name,sp)	#where to put?
		return true

	public def getVertices(rd as Reader) as bool:
		rd.bin.ReadBytes(2)	#?
		vtf = 0
		if rd.head.formatVer == 0:
			vtf = rd.getByte()
		num = rd.getLong()
		va = array[of Vertex](num)
		if vtf == 1:
			size = rd.getLong()
			for i in range(num):
				# read vertex 44
				pass
			for i in range(6):
				rd.getReal()
			hasBones = rd.getByte()
			if hasBones:
				nb = rd.getLong()
				for i in range(num):
					# read bone weights
					pass
			nmat = rd.getLong()
			for i in range(nmat):
				# read mat data44
				pass
			for i in range(nmat):
				rd.getString()	#?
			m2v = array[of long](nmat)
			for i in range(nmat):
				m2v[i] = rd.getLong()
			for i in range(nmat):
				rd.getLong()	#mat vertex num?
			for i in range(nmat):
				# read m2v[i] ushorts
				pass

		else:
			for i in range(num):
				va[i].pos 		= rd.getVector()
				va[i].rot.Xyz	= rd.getVector()
				va[i].col		= rd.getColor()
				for j in range(rd.getLong()):
					tc = rd.getVec2()
					va[i].tc = tc	if not j
				for j in range(rd.getLong()):
					rd.getVec2()	#?
			nmat = rd.getLong()
			for i in range(nmat):
				rd.getLong()	#?
				name = rd.getString()
				
		return true

	public def constructor(lc as kri.load.Context):
		con = lc
		res.register( kri.load.image.Targa() )

	public def read(path as string) as kri.Entity:	#imp: kri.res.ILoaderGen
		kri.res.Manager.Check(path)
		rd = Reader(path)
		port = Dictionary[of byte,callable(Reader) as bool]()
		port[0x7] = getMaterials
		port[0x8] = getTextures
		port[0xA] = getNodes
		port[0xE] = getBones
		port[0xF] = getVertices
		bs = rd.bin.BaseStream
		while bs.Position != bs.Length:
			code = rd.getByte()
			fun = port[code]
			assert fun(rd)
		return rd.finish()
