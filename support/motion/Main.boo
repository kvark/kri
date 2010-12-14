namespace support.motion

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public class Context:
	public final buf		= kri.frame.Buffer()
	public final pRadius	= kri.shade.par.Value[of single]('radius')
	public def constructor():
		buf.emit(0, PixelInternalFormat.Rg16f)


public class Bake( kri.rend.tech.Basic ):
	private final sa		= kri.shade.Smart()
	private final buf	as kri.frame.Buffer
	private final diModel	= Dictionary[of kri.Entity,kri.Spatial]()
	private final diCamera	= Dictionary[of kri.Camera,kri.Spatial]()
	private final pModel	= kri.lib.par.spa.Shared('s_old_mod')
	private final pCamera	= kri.lib.par.spa.Shared('s_old_cam')
	
	public def constructor(con as Context):
		super('mblur')
		buf = con.buf
		# prepare shader
		sa.add( '/lib/quat_v', '/lib/tool_v' )
		sa.add( '/motion/bake_v', '/motion/bake_f' )
		d = kri.shade.rep.Dict()
		for par as kri.meta.IBase in (pModel,pCamera):
			par.link(d)
		sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		buf.A[-2].Tex = null
		buf.resizeFrames()
		return true

	public override def process(con as kri.rend.Context) as void:
		sa.use()
		#todo: check samples?
		con.needDepth(false)
		buf.A[-2].Tex = con.Depth
		assert con.Depth and not con.Screen
		con.SetDepth(-1f,false)
		buf.activate(1)
		con.ClearColor()
		# set camera
		cam = kri.Camera.Current
		sp = kri.Spatial.Identity
		diCamera.TryGetValue(cam,sp)
		pCamera.activate(sp)
		diCamera[cam] = kri.Node.SafeWorld(cam.node)
		# iterate meshes
		for e in kri.Scene.Current.entities:
			continue	if not e.visible
			# find previous transform
			sp = kri.Spatial.Identity
			diModel.TryGetValue(e,sp)
			pModel.activate(sp)
			diModel[e] = kri.Node.SafeWorld( e.node )
			kri.Ant.Inst.params.modelView.activate( e.node )
			#draw
			e.mesh.draw(1)


public class Apply( kri.rend.Filter ):
	public def constructor(con as Context):
		sa.add('/copy_v','/motion/apply_f')
		pTex = kri.shade.par.Texture('velocity')
		pTex.Value = con.buf.A[0].Tex
		dict.var(con.pRadius)
		dict.unit(pTex)
		sa.link( kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
