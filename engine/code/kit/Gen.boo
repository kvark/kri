namespace kri.kit.gen

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


#----	COMMON DATA STORING & CREATION	----#

public struct Vertex:
	public pos as Vector4
	public rot as Quaternion

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


#----	BLOCK OBJECT	----#
# params: half-sizes of sides

private def cubeProto() as MeshData:
	md = MeshData( bm:BeginMode.Triangles, v:array[of Vertex](24) )
	units = ( Vector3.UnitX, Vector3.UnitY, Vector3.UnitZ )
	ln = List[of ushort]()
	nex = (1,2,0)
	for j2 in range(6):
		j,k,b = j2,1f,(j2<<2)
		if j2>2: j,k = (j-3),-1f
		sign = (-k,k)
		ran = (of ushort: b,b+1,b+2,b+3,b )
		for l in ran[:4]:
			md.v[l].pos = Vector4(\
				units[nex[j]]		* sign[(l>>0)&1]+\
				units[nex[nex[j]]]	* sign[(l>>1)&1]+\
				units[j]*sign[1], 1f)	#need euler here
			md.v[l].rot = Quaternion.FromAxisAngle(units[j]*k,0f)
		ln.AddRange( ran[0:3] + ran[2:5] )
	md.i = array(ln)
	return md

public def cube() as kri.Mesh:
	return common( cubeProto() )

public def block(scale as Vector3) as kri.Mesh:
	md = cubeProto()
	for i in range( md.v.Length ):
		md.v[i].pos.Xyz = Vector3.Multiply( md.v[i].pos.Xyz, scale )
	return common( md )
