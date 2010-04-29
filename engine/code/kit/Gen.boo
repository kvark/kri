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

public def entity( m as kri.Mesh, lc as kri.load.Context ) as kri.Entity:
	e = kri.Entity( mesh:m )
	tm = kri.TagMat( num:m.nPoly, mat:lc.mDef )
	e.tags.Add(tm)
	return e


#----	RAW MESH DATA	----#

public struct MeshData( kri.IGenerator[of kri.Mesh] ):
	public bm	as BeginMode
	public v	as (Vertex)
	public i	as (ushort)
	# generate a mesh from stored data
	public def generate() as kri.Mesh:	# IGenerator
		m = kri.Mesh( bm )
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
		return m
	# triangle mesh subdivision
	public def subDivide() as void:
		assert bm == BeginMode.Triangles
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

public def line() as kri.Mesh:
	m = kri.Mesh( BeginMode.Lines )
	m.nVert = 2
	m.nPoly = 1
	data = (of Vector4: Vector4(-1f,0f,0f,1f), Vector4(1f,0f,0f,1f))
	vbo = kri.vb.Attrib()
	vbo.init( data, false )
	kri.vb.enrich( vbo, 4, kri.Ant.Inst.attribs.vertex )
	return m


#----	PLANE OBJECT	----#
# param: half-size of sides

public def plane(scale as Vector2) as kri.Mesh:
	md = MeshData( bm:BeginMode.TriangleStrip, v:array[of Vertex](4) )
	sar = (-1f,1f)
	for i in range(4):
		md.v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
		md.v[i].rot = Quaternion.Identity
	return md.generate()

public def plane_tex(scale as Vector2) as kri.Mesh:
	v = array[of VertexUV](4)
	sar,str = (-1f,1f),(0f,1f)
	for i in range(4):
		v[i].uv = Vector2( str[i&1], str[i>>1] )
		v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
		v[i].rot = Quaternion.Identity
	# create mesh
	m = kri.Mesh( BeginMode.TriangleStrip )
	m.nVert = 4
	m.nPoly = 4
	# fill vbo
	vbo = kri.vb.Attrib()
	vbo.init( v, false )
	# fill semantics
	kri.vb.enrich( vbo, 4, kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat )
	kri.vb.enrich( vbo, 2, kri.Ant.Inst.attribs.tex[0] )
	# return
	m.vbo.Add(vbo)
	return m


#----	CUBE OBJECT	----#
# param: half-size of sides

public def cube(scale as Vector3) as kri.Mesh:
	md = MeshData( bm:BeginMode.Triangles )
	sar = (-1f,1f)
	verts = array( Vector4(scale.X * sar[i&1], scale.Y * sar[(i>>1)&1], scale.Z * sar[i>>2], 1f)\
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
	md.v = array( Vertex(verts[vi[i]], quats[i>>2]) for i in range(24))
	offsets = (of ushort: 0,3,2,0,2,1)
	md.i = array( cast(ushort, (i / 6)*4 + offsets[i%6]) for i in range(36))
	return md.generate()


#----	SPHERE OBJECT	----#
# param: radius

private def octahedron(scale as Vector3) as MeshData:
	md = MeshData( bm:BeginMode.Triangles )
	ar = (of Vector3:
		-Vector3.UnitZ, Vector3.UnitX,
		Vector3.UnitY, -Vector3.UnitX,
		-Vector3.UnitY, Vector3.UnitZ)
	vert = array(Vector4( Vector3.Multiply(scale,x),1f ) for x in ar)
	# no quaternions needed at this stage
	md.v = array(Vertex(v,Quaternion.Identity) for v in vert)
	md.i = (of ushort: 0,1,4, 0,2,1, 0,3,2, 0,4,3, 5,4,1, 5,1,2, 5,2,3, 5,3,4)
	return md


public def sphere(stage as uint, scale as Vector3) as kri.Mesh:
	md = octahedron(scale)
	# subdivide iterations
	for sub in range(stage):
		md.subDivide()
		# renormalize
		for i in range( md.v.Length ):
			v = md.v[i].pos.Xyz
			v.NormalizeFast()
			md.v[i].pos.Xyz = Vector3.Multiply(scale,v)
	# calculate smooth quaternions
	for i in range( md.v.Length ):
		rv = md.v[i].pos.Xyz
		xyz = rv.LengthFast
		alpha = 0.5f*PI - Asin(rv.Z / xyz)
		xy = rv.Xy.LengthFast
		if xy > 1e-10f:
			beta = Asin(rv.Y / xy)
			if rv.X < 0f: beta = PI-beta
		else: beta = 0f
		md.v[i].rot =\
			Quaternion.FromAxisAngle( Vector3.UnitZ, beta )*\
			Quaternion.FromAxisAngle( Vector3.UnitY, alpha )	
	# finish
	return md.generate()
