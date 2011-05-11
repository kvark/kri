namespace support.defer.layer

import System.Collections.Generic
import OpenTK.Graphics.OpenGL
import kri.shade


public class Fill( kri.rend.tech.General ):
	private final	fbo		as kri.buf.Holder
	private final	factory	= kri.shade.Linker()
	private	mesh	as kri.Mesh		= null
	private	dict	as kri.vb.Dict	= null
	private final	din		= Dictionary[of string,kri.meta.Hermit]()
	private	final	sVert	= Object.Load('/g/layer/pass_v')
	private final	sFrag	= Object.Load('/g/layer/pass_f')

	# init
	public def constructor(con as support.defer.Context):
		super('g.layer.fill')
		fbo = con.buf
	
	private def setBlend(str as string) as bool:
		GL.BlendEquation( BlendEquationMode.FuncAdd )
		if str == 'MIX':	
			GL.BlendFunc( BlendingFactorSrc.DstColor, BlendingFactorDest.Zero )
		elif str == 'ADD':
			GL.BlendFunc( BlendingFactorSrc.One, BlendingFactorDest.One )
		else:	return false
		return true

	# construct
	public override def construct(mat as kri.Material) as Bundle:
		bu = Bundle()
		bu.dicts.Add( mat.dict )
		sa = bu.shader
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( '/g/layer/make_v', '/g/layer/make_f' )
		sa.fragout('c_diffuse','c_specular','c_normal')
		return bu
	
	# draw
	protected override def onPass(va as kri.vb.Array, tm as kri.TagMat, bu as Bundle) as void:
		if not mesh.render( va, bu, dict, tm.off, tm.num, 1, null ):
			return
		GL.Enable( EnableCap.Blend )
		for un in tm.mat.unit:
			if 'True':	continue
			app = un.application
			if not app.prog:
				din['unit'] = un.input
				mapins = kri.load.Meta.MakeTexCoords(false,din)
				if mapins:
					sall = List[of Object](mapins)
					sall.AddRange((sVert,sFrag))
					app.prog = factory.link( sall, tm.mat.dict )
				else:	app.prog = Bundle.Empty
			if app.prog and app.prog.Failed:
				continue
			if not setBlend( app.blend ):
				kri.lib.Journal.Log("Blend: unknown mode (${app.blend})")
				setBlend( app.blend = 'MIX' )
			mesh.render( va, app.prog, dict, tm.off, tm.num, 1, null )
		GL.Disable( EnableCap.Blend )

	# resize
	public override def setup(pl as kri.buf.Plane) as bool:
		fbo.resize( pl.wid, pl.het )
		return super(pl)

	# work	
	public override def process(link as kri.rend.link.Basic) as void:
		fbo.at.depth = link.Depth
		fbo.bind()
		link.SetDepth(0f, false)
		link.ClearColor()
		scene = kri.Scene.Current
		if not scene:	return
		for e in scene.entities:
			kri.Ant.Inst.params.activate(e)
			dict = e.CombinedAttribs
			mesh = e.mesh
			addObject(e)
