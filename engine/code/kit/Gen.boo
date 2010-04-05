namespace kri.kit.gen

import OpenTK
import OpenTK.Graphics.OpenGL


#----	COMMON DATA STORING & CREATION	----#

public struct Vertex:
	public pos as Vector4
	public rot as Quaternion
	public def constructor(p as Vector4, q as Quaternion):
		pos,rot = p,q

private struct MeshData:
	public bm	as BeginMode
	public v	as (Vertex)
	public i	as (ushort)


public def common( md as MeshData ) as kri.Mesh:
	m = kri.Mesh( md.bm )
	if md.v:
		m.nVert = md.v.Length
		m.nPoly = m.nVert / m.polySize
		vbo = kri.vb.Attrib()
		vbo.init( md.v, false )
		ai = kri.vb.attr.Info( integer:false, size:4, type:VertexAttribPointerType.Float )
		ai.slot = kri.Ant.Inst.attribs.vertex
		vbo.semantics.Add(ai)
		ai.slot = kri.Ant.Inst.attribs.quat
		vbo.semantics.Add(ai)
		m.vbo.Add(vbo)
	if md.i:
		m.nPoly = md.i.Length / m.polySize
		m.ind = kri.vb.Index()
		m.ind.init( md.i, false )
	return m

public def entity( m as kri.Mesh, lc as kri.load.Context ) as kri.Entity:
	e = kri.Entity( mesh:m )
	tm = kri.TagMat( num:m.nPoly, mat:lc.mDef )
	e.tags.Add(tm)
	return e


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
# params: half-sizes of sides

public def plane(scale as Vector2) as kri.Mesh:
	md = MeshData( bm:BeginMode.TriangleStrip, v:array[of Vertex](4) )
	sar = (-1f,1f)
	for i in range(4):
		md.v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
		md.v[i].rot = Quaternion.Identity
	return common( md )


#----	CUBE OBJECT	----#
# params: half-sizes of sides

public def cube(scale as Vector3) as kri.Mesh:
	md = MeshData( bm:BeginMode.TriangleStrip )
	sar = (-1f,1f)
	verts = array( Vector4(scale.X * sar[i&1], scale.Y * sar[(i>>1)&1], scale.Z * sar[i>>2], 1f)\
		for i in range(8))
	vi = (0,1,4,5,7,1,3,0,2,4,6,7,2,3)
	qi = (0,0,0,0,1,5,5,3,3,4,4,1,2,2)
	ang = 0.5f * System.Math.PI
	quats = (of Quaternion:
		Quaternion.FromAxisAngle( Vector3.UnitX, ang ),
		Quaternion.Identity,
		Quaternion.FromAxisAngle( Vector3.UnitX, -ang ),
		Quaternion.FromAxisAngle( Vector3.UnitX, ang+ang ),
		Quaternion.FromAxisAngle( Vector3.UnitY, -ang ),
		Quaternion.FromAxisAngle( Vector3.UnitY, ang )
		)
	md.v = array( Vertex(verts[vi[i]], quats[qi[i]]) for i in range(14) )
	return common( md )
