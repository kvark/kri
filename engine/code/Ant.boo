namespace kri

import System
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


# Main engine class Ant
# Controls all events
public class Ant( OpenTK.GameWindow ):
	[getter(Inst)]
	public static inst as Ant = null		# Singleton
	public final debug	as bool				# is debug context
	public final views	= List[of View]()	# *View
	private quad	as kri.kit.gen.Quad	= null	# Standard quad
	# time
	private sw	= Diagnostics.Stopwatch()	# Time counter
	private final fps	= FpsCounter(1.0)	# FPS counter
	public anim	as ani.IBase	= null		# Animation
	public Time as double:
		get: return sw.Elapsed.TotalSeconds
	# Slots
	public final slotTechniques	= lib.Slot( lib.Const.nTech	)
	public final slotAttributes	= lib.Slot( lib.Const.nAttrib)
	public final slotParticles	= lib.Slot( lib.Const.nPart	)
	
	# main uniform dictionary
	public final dict	= shade.rep.Dict()
	# libraries
	public final params		= lib.Param(dict)
	public final shaders 	= lib.Shader()
	public final attribs	= lib.Attrib(slotAttributes)


	public def constructor(ver as int, bug as bool, wid as uint, het as uint, depth as int):
		print "Ant window ${wid}x${het}, ${depth} depth"
		gm = GraphicsMode( ColorFormat(8), depth, 0 )
		flags  = GraphicsContextFlags.ForwardCompatible
		flags |= GraphicsContextFlags.Debug	if bug
		#create GameWindow
		super(wid, het,	gm, 'kri', GameWindowFlags.Default,
			DisplayDevice.Default, 3,ver, flags)
		debug = bug
		sw.Start()
		inst = self

	public def constructor(ver as int, depth as int):
		print "Ant full-screen, ${depth} depth"
		gm = GraphicsMode( ColorFormat(8), depth, 0 )
		dd = DisplayDevice.Default
		super(dd.Width, dd.Height, gm, 'kri', GameWindowFlags.Fullscreen,
			dd,	3,ver, GraphicsContextFlags.ForwardCompatible)
		sw.Start()
		inst = self
		
	def destructor():
		inst = null
		sw.Stop()
	
	public def emitQuad() as void:
		quad.draw()

	public override def OnLoad(e as EventArgs) as void:
		slotTechniques.clear()
		slotAttributes.clear()
		quad = kri.kit.gen.Quad()
		
		# restrictions
		print GL.GetString( StringName.Version )
		print GL.GetString( StringName.ShadingLanguageVersion )
		mb = 0
		GL.GetInteger( GetPName.MaxDrawBuffers, mb )
		assert mb>=4
		
		# GL context init
		GL.ClearColor( Color4.Black )
		GL.Enable( EnableCap.CullFace )
		GL.CullFace( CullFaceMode.Back )
		GL.ClearDepth(1f)
		GL.DepthRange(0f,1f)
		GL.DepthFunc( DepthFunction.Lequal )
	
	public override def OnUnload(e as EventArgs) as void:
		views.Clear()
		shaders.Clear()
		GC.Collect()
		GC.WaitForPendingFinalizers()

	public override def OnResize(e as EventArgs) as void:
		params.parSize.Value = Vector4(1f*Width, 1f*Height, 0.5f*(Width+Height), 0f)
		for v in views:
			continue	if v.resize(Width,Height)
			raise 'View resize fail!'
	
	public override def OnUpdateFrame(e as FrameEventArgs) as void:
		return	if not anim
		tc = Time
		old = params.parTime.Value.X
		params.parTime.Value = Vector4(tc, tc-old, 0f,0f)
		anim = null	if anim.onFrame(Time)

	public override def OnRenderFrame(e as FrameEventArgs) as void:
		SwapBuffers()
		# update counter
		if fps.update(Time):
			Title = fps.gen()
		# redraw views
		for v in views:
			v.update()
