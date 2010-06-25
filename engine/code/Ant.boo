namespace kri

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


private class Config:
	private final dict	= Collections.Generic.Dictionary[of string,string]()
	public def constructor(path as string):
		for line in IO.File.ReadAllLines(path):
			continue	if line =~ /^\s*#/
			name,val = /\s*=\s*/.Split(line)
			dict[name] = val
	public def ask(name as string, default as string) as string:
		rez as string = null
		return rez	if dict.TryGetValue(name,rez)
		return default


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
	public final attribs	= lib.Attrib(slotAttributes)
	public final libShaders	as (kri.shade.Object)


	public def constructor(confile as string, depth as int):
		# read config
		conf = Config(confile)
		title	= conf.ask('Title','kri')
		shade.Code.Folder	= conf.ask('ShaderPath','../engine/shader')
		sizes	= conf.ask('Size','0x0').Split(char('x'))
		ver	= uint.Parse( conf.ask('ContextVersion','0'))
		bug	= uint.Parse( conf.ask('Debug','1'))
		fs	= uint.Parse( conf.ask('FullScreen','0'))
		wid	= uint.Parse( sizes[0] )
		het	= uint.Parse( sizes[1] )

		# prepare attributes
		dd = DisplayDevice.Default
		gm = GraphicsMode( ColorFormat(8), depth, 0 )
		conFlags  = GraphicsContextFlags.ForwardCompatible
		conFlags |= GraphicsContextFlags.Debug	if bug
		gameFlags  = GameWindowFlags.Default
		gameFlags |= GameWindowFlags.Fullscreen	if fs
		wid = dd.Width	if not wid
		het = dd.Height	if not het

		# start
		super(wid,het, gm, title, gameFlags, dd, 3,ver, conFlags)
		sw.Start()
		debug = bug>0
		inst = self
		
		# shader library init
		libShaders = array( kri.shade.Object('/lib/'+str)
			for str in ('quat_v','tool_v','fixed_v','math_f'))
		

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
