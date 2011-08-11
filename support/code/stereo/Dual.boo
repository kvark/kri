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
	public	final	xv		as Vector3
	private	final	linkBuf		= kri.rend.link.Buffer(0,0,0)
	private	final	linkScreen	= kri.rend.link.Screen()
	private	final	nEye		= kri.Node('eye')
	
	public def constructor(v as kri.View, shift as single, focus as single):
		view = v
		assert v
		xv = Vector3(shift, 0f, focus)
	
	public def setEye(eye as int, pt as par.Texture) as void:
		c = view.cam
		c.offset.X = 0f
		vin = xv	# make sure there is no offset here
		off = c.unproject(vin)
		c.offset.X = -eye * xv.X
		c.node = nEye
		nEye.local.pos.X = eye * off.X
		kri.Ant.Inst.params.activate(c)
		# render
		linkBuf.activate(true)
		view.ren.process(linkBuf)
		pt.Value = linkBuf.Input
		
	def kri.IView.update() as void:
		c = view.cam
		if not (c and view.ren and view.ren.active):
			(view as kri.IView).update()
			return
		# prepare
		kri.Scene.Current = view.scene
		view.cam.aspect = linkBuf.Frame.getInfo().Aspect
		nEye.Parent = c.node
		# render
		setEye(0-1, rMerge.texLef )	# left
		setEye(0+1, rMerge.texRit )	# right
		rMerge.process(linkScreen)
		# cleanup
		c.offset = nEye.local.pos = Vector3.Zero
		c.node = nEye.Parent
		kri.Scene.Current = null
	
	def kri.IView.resize(wid as int, het as int) as bool:
		pl = linkScreen.screen.plane
		pl.wid = wid
		pl.het = het
		linkBuf.resize(pl)
		return (view as kri.IView).resize(wid,het)
