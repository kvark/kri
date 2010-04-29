namespace kri

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#--------- Mesh ---------#

public class Mesh( vb.Storage ):
	public nVert	as uint	= 0
	public nPoly	as uint	= 0
	public ind		as vb.Index	= null
	public final drawMode	as BeginMode
	public final polySize	as uint
	
	public def constructor(dmode as BeginMode):
		drawMode,polySize = dmode,0
		polySize = 1	if dmode in (BeginMode.Points, BeginMode.LineStrip, BeginMode.LineLoop,
			BeginMode.TriangleStrip, BeginMode.TriangleFan, BeginMode.QuadStrip)
		polySize = 2	if dmode == BeginMode.Lines
		polySize = 3	if dmode == BeginMode.Triangles
		polySize = 4	if dmode == BeginMode.Quads
	
	public def constructor(m as Mesh):
		nVert	= m.nVert
		nPoly	= m.nPoly
		ind		= m.ind
		drawMode	= m.drawMode
		polySize	= m.polySize
		vbo.AddRange( m.vbo )	
	
	public def draw(off as uint, num as uint, nob as uint) as void:
		assert off>=0 and num>=0 and num+off<=nPoly
		if ind and nob != 1: # works for Uint16 indeces only
			GL.DrawElementsInstanced( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off), nob)
		elif ind:	GL.DrawElements ( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off))
		elif nob != 1:
			GL.DrawArraysInstanced( drawMode, polySize*off, polySize*num, nob)
		else:	GL.DrawArrays(		drawMode, polySize*off, polySize*num )

	# draw all polygons once
	public def draw(nob as uint) as void:
		draw(0,nPoly,nob)
	# transform points with feedback
	public def draw(tf as TransFeedback) as void:
		using tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, nVert )


#--------- Tag ---------#

public interface ITag:
	pass
	
public class TagMat(ITag):
	public off	as uint	= 0
	public num	as uint	= 0
	public mat	as Material	= null


#--------- Entity ---------#

public class Entity( vb.Storage ):
	public node	as Node		= null
	public mesh	as Mesh		= null
	public visible	as bool	= true
	public final va		= array[of vb.Array]	( lib.Const.nTech )
	public final tags	= List[of ITag]()
	
	public def constructor():
		pass
	public def constructor(e as Entity):
		# leaving unique buffers & textures
		mesh = e.mesh
		visible = e.visible
		tags.AddRange( e.tags )
	
	public def seTag[of T(ITag)]() as T:
		for it in tags:
			t = it as T
			return t	if t
		return null as T
		#return tags.Find( {t| return t isa T} ) as T
	
	public def findAny(id as int) as kri.vb.Attrib:
		at = find(id)
		return (at	if at else	mesh.find(id))
	
	public def enable(local as bool, ids as int*) as bool:
		for i in ids:
			continue if local and bind(i)
			continue if mesh.bind(i)
			return false
		mesh.ind.bind()	if mesh.ind
		return true

	public def enable(local as bool, tid as int, ids as int*) as bool:
		va[tid] = vb.Array()
		va[tid].bind()
		return enable(local,ids)
	
	# returns null if entity does't have all attributes requested
	# otherwise - a list of rejected materials
	public def check(tid as int) as kri.Material*:
		return null	if va[tid] == vb.Array.Default
		ml = List[of kri.Material]()
		for t in tags:
			tm = t as TagMat
			continue if not tm
			m = tm.mat
			ml.Add(m)	if m.tech[tid] == shade.Smart.Fixed
		return ml
