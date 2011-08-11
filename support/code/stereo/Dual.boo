namespace support.stereo

import OpenTK
import kri.shade


public class Merger( kri.rend.Basic ):
	public	final pmLef		= par.Value[of Vector4]('mask_lef')
	public	final pmRit		= par.Value[of Vector4]('mask_rit')
	public	final texLef	= par.Texture('lef')
	public	final texRit	= par.Texture('rit')
	public	final bu		= Bundle()
	public	final defMask	= Vector4(1f,0f,0f,0.5f)
	
	public def constructor():
		d = par.Dict()
		d.var(pmLef,pmRit)
		d.unit(texLef,texRit)
		bu.dicts.Add(d)
		bu.shader.add('/copy_v','/stereo/merge_f')
		setMask(defMask)
		
	public def setMask(m as Vector4) as void:
		pmLef.Value	= m
		pmRit.Value = Vector4.One-m
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate(false)
		kri.Ant.Inst.quad.draw(bu)



public class Proxy( kri.IView ):
	public	final	rMerge	= Merger()
	public	final	view	as kri.View
	public	final	hEye		as single
	public	final	focus		as single
	private	final	linkBuf		= kri.rend.link.Buffer(0,0,0)
	private	final	linkScreen	= kri.rend.link.Screen()
	private	final	nEye		= kri.Node('eye')
	
	public def constructor(v as kri.View, halfEye as single, focusDist as single):
		view = v
		assert v
		hEye = halfEye
		focus = focusDist
	
	public def setEye(eye as int) as void:
		c = view.cam
		if not c:	return
		nEye.local.pos.X = x = eye * hEye * c.rangeIn
		c.offset.X = 0f
		if eye:
			c.node = nEye
			#mid = c.rangeIn * (1-focus) + c.rangeOut * focus
			off = Vector3( x, 0f, -c.rangeIn )
			c.offset.X = c.project(off).X
			kri.Ant.Inst.params.activate(c)
		else:
			c.node = nEye.Parent
			nEye.Parent = null
			c.offset = Vector3.Zero

	def kri.IView.update() as void:
		if not (view.cam and view.ren and view.ren.active):
			(view as kri.IView).update()
			return
		kri.Scene.Current = view.scene
		view.cam.aspect = linkBuf.Frame.getInfo().Aspect
		nEye.Parent = view.cam.node
		linkBuf.activate(true)
		setEye(-1)	# left
		rMerge.texLef.Value = linkBuf.Input
		view.ren.process(linkBuf)		# into linkBuf-0
		linkBuf.activate(true)			# switch plane
		setEye(1)	# right
		rMerge.texRit.Value = linkBuf.Input
		view.ren.process(linkBuf)		# into linkBuf-1
		setEye(0)	# restore
		rMerge.process(linkScreen)
		kri.Scene.Current = null
	
	def kri.IView.resize(wid as int, het as int) as bool:
		pl = linkScreen.screen.plane
		pl.wid = wid
		pl.het = het
		linkBuf.resize(pl)
		return (view as kri.IView).resize(wid,het)
