namespace support.defer.layer

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade


public class Fill( kri.rend.tech.General ):
	public	shadeUnits		= true
	private final	fbo		as kri.buf.Holder
	private final	factory	= kri.shade.Linker(onLink)
	private	mesh	as kri.Mesh		= null
	private	vDict	as kri.vb.Dict	= null
	private final	din		= Dictionary[of string,kri.meta.Hermit]()
	private	final	sVert	= Object.Load('/g/layer/pass_v')
	private final	sFrag	= Object.Load('/g/layer/pass_f')
	private final	fout	= ('c_diffuse','c_specular','c_normal')
	# params
	private final	pDic	= par.Dict()
	private final	pZero	= par.Value[of single]('zero')
	private final	pTex	= par.Texture('texture')
	private final	mDiff	= par.Value[of Vector4]('mask_diffuse')
	private final	mSpec	= par.Value[of Vector4]('mask_specular')
	private final	mNorm	= par.Value[of Vector4]('mask_normal')

	# init
	public def constructor(con as support.defer.Context):
		super('g.layer.fill')
		fbo = con.buf
		pDic.var(mDiff,mSpec,mNorm)
		pDic.var(pZero)
		pDic.unit(pTex)
	
	private def onLink(sa as Mega) as void:
		sa.fragout(*fout)
	
	private def setBlend(str as string) as bool:
		GL.BlendEquation( BlendEquationMode.FuncAdd )
		if str == 'MIX':	
			GL.BlendFunc( BlendingFactorSrc.DstColor, BlendingFactorDest.Zero )
		elif str == 'ADD':
			GL.BlendFunc( BlendingFactorSrc.One, BlendingFactorDest.One )
		else:	return false
		return true
	
	private def setParams(app as kri.meta.UnitApp) as void:
		pZero.Value = 1f
		mDiff.Value = Vector4(1f,1f,1f,0f)
		mSpec.Value = Vector4(0f)
		mNorm.Value = Vector4(0f)

	# construct
	public override def construct(mat as kri.Material) as Bundle:
		bu = Bundle()
		bu.dicts.Add( mat.dict )
		sa = bu.shader
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( '/g/layer/make_v', '/g/layer/make_f' )
		sa.fragout(*fout)
		return bu
	
	# draw
	protected override def onPass(va as kri.vb.Array, tm as kri.TagMat, bu as Bundle) as void:
		if not mesh.render( va, bu, vDict, tm.off, tm.num, 1, null ):
			return
		if not shadeUnits:	return
		GL.Enable( EnableCap.Blend )
		for un in tm.mat.unit:
			app = un.application
			if not app.prog:
				uname = 'unit'
				din[uname] = un.input
				mapins = kri.load.Meta.MakeTexCoords(false,din)
				if mapins:
					(un as kri.meta.ISlave).link(uname,pDic)	# add offset and scale under proper names
					sall = List[of Object](mapins)
					sall.AddRange(( sVert, sFrag, un.input.Shader ))	# core shaders
					sall.AddRange( kri.Ant.Inst.libShaders )			# standard shaders
					app.prog = factory.link( sall, pDic, tm.mat.dict )	# generate program
				else:	app.prog = Bundle.Empty
			if app.prog and app.prog.Failed:
				continue
			if not setBlend( app.blend ):
				kri.lib.Journal.Log("Blend: unknown mode (${app.blend})")
				app.blend = 'MIX'
			pTex.Value = un.Value
			setParams(app)
			mesh.render( va, app.prog, vDict, tm.off, tm.num, 1, null )
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
			vDict = e.CombinedAttribs
			mesh = e.mesh
			addObject(e)
