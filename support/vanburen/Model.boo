namespace support.vb

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


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
		public def getColorByte() as Color4:
			d = 1f / 255f
			x = bin.ReadBytes(4)
			return Color4( x[0]*d, x[1]*d, x[2]*d, x[3]*d )
		public def getVec2() as Vector2:
			return Vector2( getReal(), getReal() )
		public def getVector() as Vector3:
			return Vector3( getReal(), getReal(), getReal() )
		public def getQuat() as Quaternion:
			return Quaternion.FromAxisAngle( getVector(), getReal() )

	[StructLayout(LayoutKind.Sequential)]
	public struct Vertex:
		public pos	as Vector3
		public rot	as Quaternion
		public col	as Color4
		public tc	as Vector2
	
	[StructLayout(LayoutKind.Sequential)]
	public struct BoneLink:
		public b0	as ushort
		public b1	as ushort
		public b2	as ushort
		public b3	as ushort
		public static def One(rd as Reader) as ushort:
			bid = rd.getLong() & 0xFF
			wes = rd.getReal()
			return (bid<<8) + cast(int,wes*255.99f)
		public static def Fun(n as byte) as callable(Reader) as BoneLink:
			assert n<=4
			return do(rd as Reader) as BoneLink:
				x as BoneLink
				x.b0 = One(rd)	if n>0
				x.b1 = One(rd)	if n>1
				x.b2 = One(rd)	if n>2
				x.b3 = One(rd)	if n>3
	
	public static def LoadArray[of T(struct)](rd as Reader, 
			ref ai as kri.vb.Info, fun as callable) as bool:
		#f2 as callable(Reader) as T = fun
		m = rd.ent.mesh
		ar = array[of T](m.nVert)
		for i in range( ar.Length ):
			ar[i] = fun(rd)
		v = kri.vb.Attrib()
		v.init(ar,false)
		v.Semant.Add(ai)
		m.vbo.Add(v)
		return true


	public struct Header:
		public sign			as string
		public globalScale	as single
		public coordScale	as single
		public coordName	as string
		public def constructor(rd as Reader):
			.sign = string( rd.bin.ReadChars(8) )
			unk2 = rd.bin.ReadUInt16()
			unk3 = rd.getByte()	#?
			.globalScale = rd.getReal()
			rd.getByte()	#?
			.coordScale = rd.getReal()
			rd.getByte()	#?
			.coordName = rd.getString()
			rd.getByte()	#?
			rd.bin.ReadUInt32()	#?
			unk2 = unk3 = 0

	public static final Signature	= 'B3D 1.1 '
	public final con	as kri.load.Context
	public final res	= kri.res.Manager()
	public pathPrefix	as string	= 'res/'
	# unknown vertex attributes
	public final at_un1	= kri.Ant.Inst.slotAttributes.create('un1')
	public final at_un2	= kri.Ant.Inst.slotAttributes.create('un2')
	public final at_un3	= kri.Ant.Inst.slotAttributes.create('un3')

	public def getMaterials(rd as Reader) as bool:
		# doesn't store the result
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
		# doesn't store the result
		rd.getByte()	#?
		name	= rd.getString()
		file	= rd.getString()
		wid		= rd.getLong()
		het		= rd.getLong()
		res.load[of kri.Texture]( pathPrefix+file )
		name = null
		wid = het = 0
		return true

	public def getNodes(rd as Reader) as bool:
		rd.getByte()	#?
		name = rd.getString()
		rd.ent.node = kri.Node(name)
		return true
	
	public def getFinish(rd as Reader) as bool:
		un1 = rd.getByte()	#?
		un2 = rd.getByte()	#?
		un1 = un2 = 0
		return true

	public def getBones(rd as Reader) as bool:
		name = rd.getString()
		sp = kri.Spatial.Identity
		unk1 = rd.getByte()	#?
		unk2 = rd.getByte()	#?
		flag = rd.getByte()
		if flag!=0:
			sp.pos = rd.getVector()
			if flag==3: sp.rot = rd.getQuat()
			if flag==2: sp.scale = rd.getReal()	#?
		kri.NodeBone(name,sp)	#where to put?
		unk1 = unk2 = 0
		return true


	public def getVertices(rd as Reader) as bool:
		mesh = kri.Mesh( BeginMode.Triangles )
		rd.ent.mesh = mesh
		unk1 = rd.getByte()	#?
		unk2 = rd.getByte()	#?
		unk1 = unk2 = 0
		vtf = rd.getByte()
		mesh.nVert = num = rd.getLong()
		va = array[of Vertex](num)
		if vtf == 1:
			size = rd.getLong()
			assert size == 44
			for i in range(num):
				va[i].pos 		= rd.getVector()
				va[i].rot.Xyz	= rd.getVector()
				va[i].col		= rd.getColorByte()
				va[i].tc 		= rd.getVec2()
				unk3			= rd.getVec2()
			unk3.X = 0f
			for i in range(6):
				rd.getReal()
			hasBones = rd.getByte()
			if hasBones:
				nb = rd.getLong()
				ai = kri.vb.Info(
					slot: kri.Ant.Inst.slotAttributes.getForced('skin'),
					size:4, type: VertexAttribPointerType.UnsignedShort,
					integer:false )
				LoadArray[of BoneLink]( rd, ai, BoneLink.Fun(nb) )
			nmat = rd.getLong()
			for i in range(nmat):
				tm = kri.TagMat()
				rd.ent.tags.Add(tm)
				name = rd.getString()
				rd.getString()	#mtl_id
				tm.mat = kri.Material(name)
				amb		= rd.getColor()
				diff	= rd.getColor()
				emi		= rd.getColor()
				spec	= rd.getColor()
				glossy	= rd.getReal()
				amb.A = emi.A = 0f
				con.fillMat(tm.mat, 1f,diff,spec,glossy)
				blend = rd.getString()
				mtype = rd.getString()
				blend = mtype = ''
				unk5 = rd.getLong()	#?
				for j in range(16):
					unk5 = rd.getLong()
					continue	if not unk5
					zone = rd.getString()
					tex = res.load[of kri.Texture]( pathPrefix+zone )
					con.setMatTexture(tm.mat,tex)
					unk5 = rd.getLong()
					for k in range(unk5):
						unk6 = rd.getString()	#?
					unk6 = ''
					break
				tm.mat.link()
			for i in range(nmat):
				unk6 = rd.getString()	#?
			sum as long = 0
			for tm in rd.ent.enuTags[of kri.TagMat]():
				tm.off = sum
				tm.num = rd.getLong()
				sum += tm.num
			for i in range(nmat):
				rd.getLong()	#mat vertex num?
			# read indices
			data = array[of ushort](sum)
			for i in range(sum):
				data[i] = rd.bin.ReadUInt16()
			mesh.nPoly = sum / 3
			mesh.ind = kri.vb.Index()
			mesh.ind.init(data,false)
		else:
			# not debugged yet
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
				name = ''
			rd.getByte()
			rd.getLong()
			ni = rd.getLong()
			for i in range(ni):
				rd.getLong()	#vindex
			for i in range(ni):
				rd.getByte()	#?s
		return true


	public def constructor(lc as kri.load.Context):
		con = lc
		swImage	= kri.res.Switch[of kri.Texture]()
		swImage.ext['.tga'] = kri.load.image.Targa()
		res.register(swImage)

	public def read(path as string) as kri.Entity:	#imp: kri.res.ILoaderGen
		kri.res.Manager.Check(path)
		rd = Reader(path)
		assert rd.head.sign == Signature
		port = Dictionary[of byte,callable(Reader) as bool]()
		port[0x7] = getMaterials
		port[0x8] = getTextures
		port[0xA] = getNodes
		port[0xB] = getFinish
		port[0xE] = getBones
		port[0xF] = getVertices
		bs = rd.bin.BaseStream
		while bs.Position != bs.Length:
			code = rd.getByte()
			fun = port[code]
			assert fun(rd)
		return rd.finish()
