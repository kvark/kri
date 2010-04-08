namespace kri.kit.gen

import System
import OpenTK
import OpenTK.Graphics.OpenGL


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
	public def generate() as kri.Mesh:	# IGenerator
		m = kri.Mesh( bm )
		if v:
			m.nVert = v.Length
			m.nPoly = m.nVert / m.polySize
			vbo = kri.vb.Attrib()
			vbo.init( v, false )
			ai = kri.vb.attr.Info( integer:false, size:4, type:VertexAttribPointerType.Float )
			ai.slot = kri.Ant.Inst.attribs.vertex
			vbo.semantics.Add(ai)
			ai.slot = kri.Ant.Inst.attribs.quat
			vbo.semantics.Add(ai)
			m.vbo.Add(vbo)
		if i:
			m.nPoly = i.Length / m.polySize
			m.ind = kri.vb.Index()
			m.ind.init( i, false )
		return m
	public def subDivide() as void:
		pass


#----	LINE OBJECT (-1,1)	----#

public def line() as kri.Mesh:
	m = kri.Mesh( BeginMode.Lines )
	m.nVert = 2
	m.nPoly = 1
	data = (of Vector4: Vector4(-1f,0f,0f,1f), Vector4(1f,0f,0f,1f))
	vbo = kri.vb.Attrib()
	vbo.init( data, false )
	vbo.semantics.Add( kri.vb.attr.Info(
		integer:false, slot: kri.Ant.Inst.attribs.vertex,
		size:4, type:VertexAttribPointerType.Float ))
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
	ai = kri.vb.attr.Info( integer:false, size:4, type:VertexAttribPointerType.Float )
	ai.slot = kri.Ant.Inst.attribs.vertex
	vbo.semantics.Add(ai)
	ai.slot = kri.Ant.Inst.attribs.quat
	vbo.semantics.Add(ai)
	ai.size = 2
	ai.slot = kri.Ant.Inst.attribs.tex[0]
	vbo.semantics.Add(ai)
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
	ang = 0.5f * System.Math.PI
	quats = (of Quaternion:
		Quaternion.FromAxisAngle( Vector3.UnitX, ang ),
		Quaternion.Identity,
		Quaternion.FromAxisAngle( Vector3.UnitX, -ang ),
		Quaternion.FromAxisAngle( Vector3.UnitX, ang+ang ),
		Quaternion.FromAxisAngle( Vector3.UnitY, -ang ),
		Quaternion.FromAxisAngle( Vector3.UnitY, ang )
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
	for i in range( ar.Length ):
		ar[i] = Vector3.Multiply(scale, ar[i])
	md.v = array(Vertex( Vector4(p,1f), Quaternion.Identity ) for p in ar)
	md.i = (of ushort: 0,1,4, 0,2,1, 0,3,2, 0,4,3, 5,4,1, 5,1,2, 5,2,3, 5,3,4)
	return md

public def sphere(stage as uint, scale as Vector3) as kri.Mesh:
	md = octahedron(scale)
	for sub in range(stage):
		md.subDivide()
		for i in range( md.v.Length ):
			(v = md.v[i].pos.Xyz).NormalizeFast()
			md.v[i].pos.Xyz = Vector3.Multiply(scale,v)
	for i in range( md.v.Length ):
		pass
		# calculate smooth quaternions
	return md.generate()
