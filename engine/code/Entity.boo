namespace kri

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


#--------- Mesh ---------#

class Mesh( vb.attr.Storage ):
	public nVert	as uint	= 0
	public nPoly	as uint	= 0
	public ind		as vb.Index	= null
	public final drawMode	as BeginMode
	public final polySize	as uint
	public final uvNames	= array[of string]( Ant.Inst.attribs.tex.Length )
	
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
		#TODO: use core
		if ind and nob != 1: # works for Uint16 indeces only
			GL.DrawElementsInstanced( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off), nob)
		elif ind:	GL.DrawElements ( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off))
		elif nob != 1:
			GL.DrawArraysInstanced( drawMode, polySize*off, polySize*num, nob)
		else:	GL.DrawArrays(		drawMode, polySize*off, polySize*num )

	# draw all polygons once
	public def draw() as void:
		draw(0,nPoly,1)
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

public class Entity( vb.attr.Storage ):
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
	
	public def enable(ids as int*) as bool:
		for i in ids:
			continue if bind(i)
			continue if mesh.bind(i)
			return false
		mesh.ind.bind()	if mesh.ind
		return true

	public def enable(tid as int, ids as int*) as bool:
		va[tid] = vb.Array()
		va[tid].bind()
		return enable(ids)
	
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


#--------- Quad ---------#

public class Quad:
	public final	va = vb.Array()
	protected final	data = vb.Attrib()
	public def constructor():
		va.bind()
		data.init[of Vector2h]((
			Vector2h(-1f,-1f),	Vector2h(1f,-1f),
			Vector2h(-1f,1f),	Vector2h(1f,1f),
			), false)
		id = Ant.Inst.attribs.vertex
		ai = vb.attr.Info(slot:id, size:2, type:VertexAttribPointerType.HalfFloat)
		data.semantics.Add(ai)
		data.attribAll()
		vb.Array.unbind()
	public def draw() as void:
		va.bind()
		GL.DrawArrays( BeginMode.TriangleStrip, 0, 4 )


#--------- Batch ---------#

public struct Batch:	# why struct?
	public e	as Entity
	public va	as vb.Array
	public sa	as shade.Smart
	public up	as callable() as int
	public off	as int
	public num	as int

	public def draw() as void:
		nob = up()
		Ant.Inst.params.modelView.activate( e.node )
		va.bind()
		sa.use()
		e.mesh.draw(off,num,nob)
		
	public class CompMat( IComparer[of Batch] ):
		public def Compare(a as Batch, b as Batch) as int:
			r = a.sa.id - b.sa.id
			return r	if r
			r = a.va.id - b.va.id
			return r
	public static cMat	= CompMat()
