namespace kri.kit.gen

import System.Math
import OpenTK
import OpenTK.Graphics.OpenGL


#--------- QUAD ---------#

public class Quad:
	public final	va		= kri.vb.Array()
	protected final	data	= kri.vb.Attrib()
	public def constructor():
		va.bind()
		data.init[of Vector2h]((
			Vector2h(-1f,-1f),	Vector2h(1f,-1f),
			Vector2h(-1f,1f),	Vector2h(1f,1f),
			), false)
		id = kri.Ant.Inst.attribs.vertex
		ai = kri.vb.Info(slot:id, size:2, type:VertexAttribPointerType.HalfFloat)
		data.Semant.Add(ai)
		data.attribFirst()
		kri.vb.Array.unbind()
	public def draw() as void:
		va.bind()
		GL.DrawArrays( BeginMode.TriangleStrip, 0, 4 )



#----	COMMON DATA STORING & CREATION	----#

[StructLayout(LayoutKind.Sequential)]
public struct Vertex:
	public pos	as Vector4
	public rot	as Quaternion
	public def constructor(p as Vector4, q as Quaternion):
		pos,rot = p,q

[StructLayout(LayoutKind.Sequential)]
public struct VertexUV:
	public pos	as Vector4
	public rot	as Quaternion
	public uv	as Vector2



public class Entity( kri.Entity ):
	public def constructor( m as kri.Mesh, lc as kri.load.Context ):
		super()
		self.mesh = m
		tm = kri.TagMat( num:m.nPoly, mat:lc.mDef )
		tags.Add(tm)



#----	RAW MESH DATA	----#

public struct Constructor:
	public v	as (Vertex)
	public i	as (ushort)
	
	# fill up the mesh data
	public def apply(m as kri.Mesh) as void:
		if v:
			m.nVert = v.Length
			m.nPoly = m.nVert / m.polySize
			vbo = kri.vb.Attrib()
			vbo.init( v, false )
			kri.vb.enrich( vbo, 4, kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat )
			m.vbo.Add(vbo)
		if i:
			m.nPoly = i.Length / m.polySize
			m.ind = kri.vb.Index()
			m.ind.init( i, false )
	
	# triangle mesh subdivision
	public def subDivide() as void:
		# it has to be triangle list! no check is possible here
		assert v and i and i.Length%3 == 0
		nPoly = i.Length / 3
		v2 = array[of Vertex]( v.Length + 3*nPoly )
		v.CopyTo(v2,0)
		i2 = array[of ushort]( 3*nPoly * 4 )
		# iterating over polygons
		def avg(ref a as Vertex, ref b as Vertex):
			return Vertex( Vector4.Lerp(a.pos,b.pos,0.5), a.rot )
		for j in range(nPoly):
			i0 = array(i[j*3+k] for k in range(3))
			x = array(v[k] for k in i0)
			j2 = v.Length + j*3
			array(avg(x[k],x[(k+1)%3]) for k in range(3)).CopyTo(v2,j2)
			j3 = 3*j*4
			(of ushort: j2+0,j2+1,j2+2) .CopyTo(i2,j3+0)
			(of ushort: i0[0],j2+0,j2+2).CopyTo(i2,j3+3)
			(of ushort: j2+0,i0[1],j2+1).CopyTo(i2,j3+6)
			(of ushort: j2+2,j2+1,i0[2]).CopyTo(i2,j3+9)
		i,v = i2,v2



#----	LINE OBJECT (-1,1)	----#

public class Line( kri.Mesh ):
	public def constructor():
		super( BeginMode.Lines )
		self.nVert = 2
		self.nPoly = 1
		data = (of Vector4: Vector4(-1f,0f,0f,1f), Vector4(1f,0f,0f,1f))
		vat = kri.vb.Attrib()
		vat.init( data, false )
		kri.vb.enrich( vat, 4, kri.Ant.Inst.attribs.vertex )
		vbo.Add(vat)



#----	PLANE OBJECT	----#
# param: half-size of sides

public class Plane( kri.Mesh ):
	public def constructor(scale as Vector2):
		con = Constructor( v:array[of Vertex](4) )
		sar = (-1f,1f)
		for i in range(4):
			con.v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
			con.v[i].rot = Quaternion.Identity
		super( BeginMode.TriangleStrip )
		con.apply(self)

public class PlaneTex( kri.Mesh ):
	public def constructor(scale as Vector2):
		v = array[of VertexUV](4)
		sar,str = (-1f,1f),(0f,1f)
		for i in range(4):
			v[i].uv = Vector2( str[i&1], str[i>>1] )
			v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
			v[i].rot = Quaternion.Identity
		# create mesh
		super( BeginMode.TriangleStrip )
		self.nVert = 4
		self.nPoly = 4
		# fill vbo
		vat = kri.vb.Attrib()
		vat.init( v, false )
		# fill semantics
		kri.vb.enrich( vat, 4, kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat )
		kri.vb.enrich( vat, 2, kri.Ant.Inst.attribs.tex[0] )
		# return
		vbo.Add(vat)



#----	CUBE OBJECT	----#
# param: half-size of sides

public class Cube( kri.Mesh ):
	public def constructor(scale as Vector3):
		con = Constructor()
		sar = (-1f,1f)
		verts = array( Vector4( scale.X * sar[i&1],\
			scale.Y * sar[(i>>1)&1],\
			scale.Z * sar[i>>2], 1f)\
			for i in range(8))
		#vi = (0,1,4,5,7,1,3,0,2,4,6,7,2,3)	# tri-strip version
		vi = (0,4,5,1, 4,6,7,5, 6,2,3,7, 2,0,1,3, 2,6,4,0, 1,5,7,3)
		ang = 0.5f * PI
		quats = (of Quaternion:
			Quaternion.FromAxisAngle( Vector3.UnitX, ang ),		#-Y
			Quaternion.Identity,								#+Z
			Quaternion.FromAxisAngle( Vector3.UnitX, -ang ),	#+Y
			Quaternion.FromAxisAngle( Vector3.UnitX, ang+ang ),	#-Z
			Quaternion.FromAxisAngle( Vector3.UnitY, -ang ),	#-X
			Quaternion.FromAxisAngle( Vector3.UnitY, ang )		#+X
			)
		con.v = array( Vertex(verts[vi[i]], quats[i>>2]) for i in range(24))
		offsets = (of ushort: 0,3,2,0,2,1)
		con.i = array( cast(ushort, (i / 6)*4 + offsets[i%6]) for i in range(36))
		super( BeginMode.Triangles )
		con.apply(self)



#----	SPHERE OBJECT	----#
# param: radius

public class Sphere( kri.Mesh ):	
	private static def Octahedron(scale as Vector3) as Constructor:
		ar = (of Vector3:
			-Vector3.UnitZ, Vector3.UnitX,
			Vector3.UnitY, -Vector3.UnitX,
			-Vector3.UnitY, Vector3.UnitZ)
		vert = array(Vector4( Vector3.Multiply(scale,x),1f ) for x in ar)
		# no quaternions needed at this stage
		con = Constructor()
		con.v = array(Vertex(v,Quaternion.Identity) for v in vert)
		con.i = (of ushort: 0,1,4, 0,2,1, 0,3,2, 0,4,3, 5,4,1, 5,1,2, 5,2,3, 5,3,4)
		return con
	
	public def constructor(stage as uint, scale as Vector3):
		con = Octahedron(scale)
		# subdivide iterations
		for sub in range(stage):
			con.subDivide()
			# renormalize
			for i in range( con.v.Length ):
				v = con.v[i].pos.Xyz
				v.NormalizeFast()
				con.v[i].pos.Xyz = Vector3.Multiply(scale,v)
		# calculate smooth quaternions
		for i in range( con.v.Length ):
			rv = con.v[i].pos.Xyz
			xyz = rv.LengthFast
			alpha = 0.5f*PI - Asin(rv.Z / xyz)
			xy = rv.Xy.LengthFast
			if xy > 1e-10f:
				beta = Asin(rv.Y / xy)
				if rv.X < 0f: beta = PI-beta
			else: beta = 0f
			con.v[i].rot =\
				Quaternion.FromAxisAngle( Vector3.UnitZ, beta )*\
				Quaternion.FromAxisAngle( Vector3.UnitY, alpha )	
		# finish
		super( BeginMode.Triangles )
		con.apply(self)



#----	LANDSCAPE	----#
# param: height map

public class Landscape( kri.Mesh ):
	public def constructor(hm as (single,2), scale as Vector3):
		con = Constructor()
		con.v = array[of Vertex]( len(hm) )
		assert len(hm,0) and len(hm,1)
		
		def hv(x as int,y as int):
			z = 0f
			if x>=0 and x<len(hm,0) and y>=0 and y<len(hm,1):
				z = hm[x,y]
			return Vector3(x,y,z)
		
		for y in range(len(hm,1)):
			for x in range(len(hm,0)):
				id = y*len(hm,0) + x
				con.v[id].pos = Vector4(
					Vector3.Multiply( scale, hv(x,y) ),	1f)
				normal = Vector3.Divide( Vector3.Cross(
					hv(x+1,y) - hv(x-1,y),
					hv(x,y+1) - hv(x,y-1)),
					scale)
				normal.Normalize()
				nz = Vector3.Cross( Vector3.UnitZ, normal )
				con.v[id].rot = Quaternion.Normalize( Quaternion(
					nz* (1f - Vector3.Dot(normal,Vector3.UnitZ)),
					nz.LengthFast ))
		
		con.i = array[of ushort]( (len(hm,1)-1) * (2*len(hm,0)+1) )
		for y in range( len(hm,1)-1 ):
			id = y*( 2*len(hm,0)+1 )
			for x in range(len(hm,0)):
				x2 = ( x, len(hm,0)-1-x )[y&1]
				for d in range(2):
					con.i[id + x+x+d] = (y+1-d)*len(hm,0) + x2
			id += 2*len(hm,0)
			con.i[id] = con.i[id-1]
		
		super( BeginMode.TriangleStrip )
		con.apply(self)
