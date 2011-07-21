namespace support.asm

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


public struct Element( kri.meta.IBase ):
	# internal state
	public	final	name	as string
	public	final	node	as kri.Node
	public	final	mat		as kri.Material
	public	final	range	as Range
	# shader params
	public	final	pNode	as kri.lib.par.spa.Linked
	public	final	pArea	as kri.shade.par.Value[of Vector4]
	public	final	pChan	as kri.shade.par.Value[of int]
	# methods
	public def constructor(str as string, n as kri.Node, tm as kri.TagMat):
		name = str
		node = n
		mat = tm.mat
		range = Range(tm)
		pNode = kri.lib.par.spa.Linked(str)
		pArea = kri.shade.par.Value[of Vector4](str)
		pChan = kri.shade.par.Value[of int](str)
	
	kri.INamed.Name as string:
		get: return name
	def kri.meta.IBase.link(d as kri.shade.par.Dict) as void:
		(pNode as kri.meta.IBase).link(d)
		d.var(pArea)
		d.var(pChan)



public class Scene:
	public	final	conMesh		as Mesh		= null
	public	final	conTex		as Texture	= null
	public	final	mesh	= kri.Mesh( BeginMode.Triangles )
	public	final	elems	as (Element)	= null
	[Getter(Current)]
	internal	static	current	as Scene		= null
	private	numEl	= 0
	
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
	
	public def constructor(n as int, scene as kri.Scene):
		elems = array[of Element](n)
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
		# push data
		for m in enuMeshes(scene):
			conMesh.copyData(m)
		for t in enuTextures(scene):
			conTex.add(t)
		mesh.nVert = conMesh.nVert
		# generate element list
		mesh.ind = ind = IndexAccum()
		ind.init( np<<2 )
		for e in scene.entities:
			for tm in e.enuTags[of kri.TagMat]():
				str = "el[${numEl}]."
				conMesh.copyIndex( e.mesh, ind, tm )
				elems[numEl] = Element(str, e.node, tm)
				numEl += 1
		mesh.nPoly = ind.curNumber
