namespace support.vb

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


public class Model( kri.data.ILoaderGen[of kri.Entity] ):
	public class Reader:
		public final bin	as IO.BinaryReader
		public final head	as Header
		public final ent	= kri.Entity()
		public final bones	= List[of kri.NodeBone]()
		
		public def constructor(path as string):
			bin = IO.BinaryReader( IO.File.OpenRead(path) )
			head = Header(self)
		public def finish() as kri.Entity:
			bin.Close()
			return ent
		public def makeSkeleton() as void:
			tag = support.skin.Tag()
			tag.skel = kri.Skeleton( null, bones.Count )
			bones.CopyTo( tag.skel.bones )
			ent.tags.Add(tag)
		
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
		public pos	as Vector4
		public rot	as Quaternion
		public tc	as Vector2
		public col	as int
	
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
				return x
	
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
	
	public static def QuatBasis(hand as single, ref a as Vector3, ref b as Vector3, ref c as Vector3) as Quaternion:
		q = Quaternion()
		q.W = Math.Sqrt(Math.Max(0f, hand +a.X +b.Y +c.Z))
		q.X = Math.Sqrt(Math.Max(0f, hand +a.X -b.Y -c.Z))
		q.Y = Math.Sqrt(Math.Max(0f, hand -a.X +b.Y -c.Z))
		q.Z = Math.Sqrt(Math.Max(0f, hand -a.X -b.Y +c.Z))
		q.X *= 0.5f * Math.Sign(c.Y-b.Z)
		q.Y *= 0.5f * Math.Sign(a.Z-c.X)
		q.Z *= 0.5f * Math.Sign(b.X-a.Y)
		return Quaternion.Invert( Quaternion.Normalize(q) )
	
	public static def ProcessVertices(vin as (ushort), var as (Vertex)) as kri.vb.Attrib:
		# prepare quaternions
		tar = array[of Vector4]( var.Length )
		for i in range(tar.Length):
			tar[i] = Vector4.Zero
		for i in range(vin.Length / 3):
			v0 = var[vin[i*3+0]]
			v1 = var[vin[i*3+1]]
			v2 = var[vin[i*3+2]]
			va = (v1.pos - v0.pos).Xyz
			vb = (v2.pos - v0.pos).Xyz
			ta = v1.tc - v0.tc
			tb = v2.tc - v0.tc
			tan = va*tb.Y - vb*ta.Y
			tan.NormalizeFast()
			bit = vb*ta.X - va*tb.X
			bit.NormalizeFast()
			n0 = Vector3.Cross(va,vb)
			n0.NormalizeFast()
			n1 = Vector3.Cross(tan,bit)
			hand = Vector3.Dot(n0,n1)
			x = Vector4(tan,hand)
			for j in range(i*3,i*3+3):
				#assert tar[vin[j]].W * x.W >= 0f
				tar[vin[j]] += x
		for i in range(tar.Length):
			var[i].pos.W = hand = Math.Sign( tar[i].W )
			tan = tar[i].Xyz
			tan.Normalize()
			nor = Vector3.NormalizeFast( var[i].rot.Xyz )
			bit = Vector3.Cross(nor,tan) * hand
			tan = Vector3.Cross(bit,nor)
			var[i].rot = QuatBasis(1f,tan,bit,nor)
		# book-keeping
		rez = kri.vb.Attrib()
		ai = kri.vb.Info( size:4, integer:false,
			type: VertexAttribPointerType.Float )
		ai.name = 'vertex'
		rez.Semant.Add(ai)
		ai.name = 'quat'
		rez.Semant.Add(ai)
		ai.name = 'tex0'
		ai.size = 2
		rez.Semant.Add(ai)
		ai.name = 'col0'
		ai.size = 4
		ai.type = VertexAttribPointerType.UnsignedByte
		rez.Semant.Add(ai)
		# push to GPU
		rez.init(var,false)
		return rez


	public struct Header:
		public sign			as string
		public globalScale	as single
		public coordScale	as single
		public coordName	as string
		public texMod		as long
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
			texMod = rd.getLong()
			unk2 = unk3 = 0

	public static final Signature	= 'B3D 1.1 '
	public final con	as kri.load.Context
	public final data	= kri.data.Manager()
	public pathPrefix	as string	= 'res/'


	public def getMaterials(rd as Reader) as bool:
		# doesn't store the result
		rd.getString()	#mtl_id
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
		con.fillMat(m, emi,diff,spec,glossy)
		m.link()
		# read the rest
		blend = rd.getString()
		mtype = rd.getString()
		flag1 = rd.getLong()
		flag2 = rd.getLong()
		# unused vars
		amb.A = alpha
		blend = mtype
		flag1 = flag2
		return true

	public def getTextures(rd as Reader) as bool:
		# doesn't store the result
		rd.getByte()	#?
		name	= rd.getString()
		file	= rd.getString()
		wid		= rd.getLong()
		het		= rd.getLong()
		data.load[of kri.buf.Texture]( pathPrefix+file )
		name = null
		wid = het
		return true

	public def getNodes(rd as Reader) as bool:
		parent = rd.getByte()
		parent = 0
		name = rd.getString()
		n = kri.Node(name)
		n.Parent = rd.ent.node
		rd.ent.node = n
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
			sp.pos = rd.getVector()	#?
			if flag==3: sp.rot = rd.getQuat()
			if flag==2: sp.scale = rd.getReal()	#?
		bon = kri.NodeBone(name,sp)	#where to put?
		rd.bones.Add(bon)
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
				va[i].pos.Xyz	= rd.getVector()
				va[i].rot.Xyz	= rd.getVector()
				va[i].col		= rd.bin.ReadInt32()
				va[i].tc 		= rd.getVec2()
				unk3			= rd.getVec2()
			# read bones
			unk3.X = 0f
			for i in range(6):
				rd.getReal()
			hasBones = rd.getByte()
			if hasBones:
				rd.makeSkeleton()
				nb = rd.getLong()
				ai = kri.vb.Info( name:'skin', size:4,
					type: VertexAttribPointerType.UnsignedShort,
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
				amb.A = 0f
				con.fillMat(tm.mat, emi,diff,spec,glossy)
				blend = rd.getString()
				mtype = rd.getString()
				blend = mtype
				unk5 = rd.getLong()	#?
				for j in range(16):
					unk5 = rd.getLong()
					continue	if not unk5
					zone = rd.getString()
					tex = data.load[of kri.buf.Texture]( pathPrefix+zone )
					tex.setState(0,true,true)
					con.setMatTexture( tm.mat, tex )
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
				num = rd.getLong()
				tm.num = num / 3
				sum += num
			for i in range(nmat):
				rd.getLong()	#mat vertex num?
			# read indices
			dar = array[of ushort](sum)
			for i in range(sum):
				dar[i] = rd.bin.ReadUInt16()
			mesh.nPoly = sum / 3
			mesh.ind = kri.vb.Object()
			mesh.ind.init(dar,false)
			# deferred vertex push
			vat = ProcessVertices(dar,va)
			rd.ent.mesh.vbo.Add(vat)
		else:
			# not debugged yet
			for i in range(num):
				va[i].pos.Xyz	= rd.getVector()
				va[i].rot.Xyz	= rd.getVector()
				va[i].col		= rd.bin.ReadUInt32()
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
		swImage	= kri.data.Switch[of kri.buf.Texture]()
		swImage.ext['.tga'] = kri.load.image.Targa()
		data.register(swImage)

	public def read(path as string) as kri.Entity:	#imp: kri.res.ILoaderGen
		if not kri.data.Manager.Check(path):
			return null
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
