namespace support.defer

import OpenTK.Graphics.OpenGL
import kri.shade

#---------	DEFERRED BASE APPLY		--------#

public class ApplyBase( kri.rend.Basic ):
	protected	final	buSimple		= Bundle()
	public		initOnly			= false
	# custom activation
	private virtual def onInit() as void:
		pass
	private virtual def onDraw() as void:
		pass
	# create
	protected def constructor(con as Context):
		buSimple.dicts.Add( con.dict )
		buSimple.shader.add( '/lib/quat_v','/lib/tool_v','/lib/defer_f','/lib/math_f' )
		buSimple.shader.add( con.sh_apply, con.sh_diff, con.sh_spec )
	# work
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate(false)
		onInit()
		if initOnly:	return
		# enable depth check
		link.activate( link.Target.Same, 0f, false )
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		# add lights
		using blend = kri.Blender():
			blend.add()
			onDraw()
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )


#---------	DEFERRED STANDARD APPLY		--------#

public class Apply( ApplyBase ):
	private final bv		= Bundle()
	private final texShadow	as par.Texture
	private final sphere	as kri.gen.Frame
	private final cone		as kri.gen.Frame
	private final noShadow	as kri.buf.Texture
	# init
	public def constructor(lc as support.light.Context, con as Context):
		super(con)
		sphere = con.sphere
		cone = con.cone
		texShadow = lc.texLit
		noShadow = lc.defShadow
		buSimple.dicts.Add( lc.dict )
		buSimple.shader.add( lc.getApplyShader() )
		buSimple.shader.add('/g/apply_v')
		# fill shader
		bv.shader.add( '/copy_v', '/g/init_f' )
		bv.dicts.Add( con.dict )
	# shadow
	private def bindShadow(t as kri.buf.Texture) as Bundle:
		if t:
			texShadow.Value = t
			t.filt(false,false)
			t.shadow(false)
		else:
			texShadow.Value = noShadow
		return buSimple
	# work
	private override def onInit() as void:
		kri.Ant.Inst.quad.draw(bv)
	private override def onDraw() as void:
		scene = kri.Scene.Current
		if not scene:	return
		for l in scene.lights:
			frame as kri.gen.Frame = {
				kri.Light.Type.Omni:	sphere,
				kri.Light.Type.Spot:	cone,
			}[l.getType()]
			if not frame:
				kri.lib.Journal.Log("Light: no volume found for light (${l})")
				continue
			bu = bindShadow( l.depth )
			kri.Ant.Inst.params.activate(l)
			frame.draw(bu)
