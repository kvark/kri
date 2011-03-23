namespace kri

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#--------- Mesh ---------#

public class Mesh( vb.Storage ):
	public nVert	as uint	= 0
	public nPoly	as uint	= 0
	public ind		as vb.Object	= null
	public final drawMode	as BeginMode
	public final polySize	as uint
	public NumElements as uint:
		get: return (nVert,nPoly)[ind!=null]
	
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
	
	public def allocate() as void:
		for v in vbo:
			v.initUnit(nVert)
		assert not ind
	
	public def getTotalSize() as uint:
		rez = 0
		for v in vbo:
			rez += v.unitSize()
		return rez * nVert
	
	#---	render functions	---#
	
	public def render(vao as vb.Array, bu as shade.Bundle, dict as vb.Dict, off as uint, num as uint, nob as uint, tf as TransFeedback) as bool:
		if not bu.pushAttribs(ind,vao,dict):
			assert not 'good'
			return false
		bu.activate()
		if tf:
			draw(tf)
		elif nob>0:
			draw(off,num,nob)
		return true
	
	public def render(vao as vb.Array, bu as shade.Bundle, dict as vb.Dict, nob as uint, tf as TransFeedback) as bool:
		return render(vao,bu,dict,0,NumElements,nob,tf)
	
	public def render(vao as vb.Array, bu as shade.Bundle, tf as TransFeedback) as bool:
		return render( vao, bu, vb.Dict(self), 1, tf)
	
	#---	internal drawing functions	---#
	
	protected def draw(off as uint, num as uint, nob as uint) as void:
		assert off>=0 and num>=0
		if ind:
			assert num+off<=nPoly
			assert num*polySize <= kri.Ant.Inst.caps.elemIndices
		else:
			assert num+off<=nVert
		assert nVert <= kri.Ant.Inst.caps.elemVertices
		# works for ushort indices only
		if ind and nob != 1:
			GL.DrawElementsInstanced( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off), nob)
		elif ind:	GL.DrawElements ( drawMode, polySize*num,
				DrawElementsType.UnsignedShort, IntPtr(polySize*2*off))
		elif nob != 1:
			GL.DrawArraysInstanced( drawMode, polySize*off, polySize*num, nob)
		else:	GL.DrawArrays(		drawMode, polySize*off, polySize*num )

	# draw all polygons once
	protected def draw(nob as uint) as void:
		draw(0,NumElements,nob)
	# transform points with feedback
	protected def draw(tf as TransFeedback) as void:
		using tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, nVert )
		assert tf.result() == nVert


#--------- Tag ---------#

public interface ITag:
	pass
	
public class TagMat(ITag):
	public off	as uint	= 0
	public num	as uint	= 0
	public mat	as Material	= null


#--------- Entity ---------#

public class Entity( kri.ani.data.Player ):
	public node		as Node	= null
	public mesh		as Mesh	= null
	public visible	as bool	= true
	public final store	= vb.Storage()
	public final va		= array[of vb.Array]	( kri.Ant.Inst.techniques.Size )
	public final tags	= List[of ITag]()
	
	public CombinedAttribs as vb.Dict:
		get: return vb.Dict(mesh,store)
	
	public def constructor():
		pass
	public def constructor(e as Entity):
		mesh = e.mesh
		visible = e.visible
		tags.AddRange( e.tags )
	
	public def touch() as void:
		pass
	
	public def seTag[of T(ITag)]() as T:
		for it in tags:
			t = it as T
			return t	if t
		return null as T
		#return tags.Find( {t| return t isa T} ) as T
	
	public def enuTags[of T(ITag)]() as (T):
		tlis = List[of T]()
		for it in tags:
			t = it as T
			tlis.Add(t)	if t
		return tlis.ToArray()
	
	public def findAny(name as string) as kri.vb.Attrib:
		at = store.find(name)
		return (at	if at else	mesh.find(name))
	
	# returns null if entity does't have all attributes requested
	# otherwise - a list of rejected materials
	public def check(tid as int) as kri.Material*:
		return null	if va[tid] == vb.Array.Default
		ml = List[of kri.Material]()
		for t in tags:
			tm = t as TagMat
			if not tm:
				continue	
			m = tm.mat
			if m.tech[tid] == shade.Bundle.Empty:
				ml.Add(m)
		return ml
	
	public def render(vao as vb.Array, bu as shade.Bundle, off as uint, num as uint, nob as uint) as bool:
		assert mesh and store
		return mesh.render( vao,bu, CombinedAttribs, off,num,nob,null )
	
	public def render(vao as vb.Array, bu as shade.Bundle) as bool:
		assert mesh and store
		return mesh.render( vao,bu, CombinedAttribs, 1,null )
