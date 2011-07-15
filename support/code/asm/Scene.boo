namespace support.asm

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Element:
	public	node	as kri.Node
	public	mat		as kri.Material
	public	range	as Range


public class View( kri.View ):
	public final elems	as (Element)
	public def constructor(n as int):
		elems = array[of Element](n)



public class Scene:
	public	final	conMesh		as Mesh		= null
	public	final	conTex		as Texture	= null
	public	final	mesh	= kri.Mesh( BeginMode.Triangles )
	
	public def enuMeshes(scene as kri.Scene) as kri.Mesh*:
		mlis = List[of kri.Mesh]()
		for e in scene.entities:
			m = e.mesh
			if m==null or m in mlis:
				continue
			mlis.Add(m)
			yield m
	
	public def enuTextures(scene as kri.Scene) as kri.buf.Texture*:
		tlis = List[of kri.buf.Texture]()
		for e in scene.entities:
			for tag in e.enuTags[of kri.TagMat]():
				for un in tag.mat.unit:
					t = un.Value
					if t==null or t in tlis:
						continue
					tlis.Add(t)
					yield t
	
	public def constructor(scene as kri.Scene):
		square = nv = np = 0
		# gather statistiscs
		for m in enuMeshes(scene):
			nv += m.nVert
			np += m.nPoly
		for t in enuTextures(scene):
			square += t.Area
		size = 1
		for i in range(1,14):
			if (1<<(i+i-1))>square:
				size = 1<<i
				break
		# initialize constructors
		conMesh = Mesh(nv)
		conTex = Texture(size)
		mesh.buffers.Add( conMesh.data )
		mesh.ind = ind = IndexAccum()
		ind.init( np<<2 )
		# push data
		for m in enuMeshes(scene):
			conMesh.copyData(m)
			conMesh.copyIndex(m,ind)
		for t in enuTextures(scene):
			conTex.add(t)
		mesh.nVert = conMesh.nVert
		mesh.nPoly = ind.curNumber
