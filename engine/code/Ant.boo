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
		if dict.TryGetValue(name,rez):
			dict[name] = null
			return rez
		return default
	public def getUnused() as string*:
		return ( d.Key	for d in dict	if d.Value!=null )


public interface IExtension:
	def attach(nt as load.Native) as void


# Main engine class Ant
# Controls all events
public class Ant( OpenTK.GameWindow ):
	[getter(Inst)]
	public static inst as Ant = null		# Singleton
	public final caps	as Capabilities		# Render capabilities
	public final debug	as bool				# is debug context
	public final views	= List[of View]()	# *View
	private quad	as kri.kit.gen.Frame	= null	# Standard quad
	# time
	private sw	= Diagnostics.Stopwatch()	# Time counter
	private final fps	as FpsCounter		# FPS counter
	public anim	as ani.IBase	= null		# Animation
	public Time as double:
		get: return sw.Elapsed.TotalSeconds
	public PointerNdc as Vector3:
		get: return Vector3.Multiply( Vector3(
			0f + Mouse.X / params.parSize.Value.X,
			1f - Mouse.Y / params.parSize.Value.Y,
			0f ), 2f) - Vector3.One
	# Slots
	public final slotTechniques	= lib.Slot( lib.Const.nTech	)
	public final slotAttributes	= lib.Slot( lib.Const.nAttrib )
	public final slotParticles	= lib.Slot( lib.Const.nPart	)
	
	# extensions
	public final extensions	= List[of IExtension]()
	public final loaders	as load.Standard
	# resource manager
	public final resMan		= res.Manager()
	# main uniform dictionary
	public final dict		= shade.rep.Dict()
	# libraries
	public final params		= lib.Param(dict)
	public final attribs	= lib.Attrib(slotAttributes)
	public final libShaders	as (kri.shade.Object)


	public def constructor(confile as string, depth as int):
		# read config
		conf = Config(confile)
		title	= conf.ask('Title','kri')
		shade.Code.Folder	= conf.ask('ShaderPath','../../engine/shader')
		sizes	= conf.ask('Window','0x0').Split(char('x'))
		context	= conf.ask('Context','0')
		bug = context.EndsWith('d')
		ver = uint.Parse( context.TrimEnd(char('r'),char('d')) )
		wid	= uint.Parse( sizes[0] )
		het	= uint.Parse( sizes[1] )
		fs	= (sizes[0] + sizes[1] == 0)
		period	= single.Parse( conf.ask('StatPeriod','1.0') )
		
		# check configuration completeness
		unused = array( conf.getUnused() )
		if unused.Length:
			raise 'Unknown config parameter: ' + unused[0]

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
		fps = FpsCounter(period,title)
		sw.Start()
		caps = Capabilities()
		debug = bug
		inst = self
		
		# shader library init
		resMan.register( shade.Loader() )
		libShaders = array( resMan.load[of kri.shade.Object]('/lib/'+str)
			for str in ('quat_v','tool_v','orient_v','fixed_v','math_f'))
		# extensions init
		loaders = load.Standard()
		extensions.Add(loaders)
		

	def destructor():
		inst = null
		sw.Stop()
	
	public def emitQuad() as void:
		quad.draw()

	public override def OnLoad(e as EventArgs) as void:
		slotTechniques.clear()
		slotAttributes.clear()
		quad = kri.kit.gen.Frame( kri.kit.gen.Quad() )
		
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
		tc = Time
		old = params.parTime.Value.X
		params.parTime.Value = Vector4(tc, tc-old, 0f,0f)
		anim = null	if anim and anim.onFrame(Time)

	public override def OnRenderFrame(e as FrameEventArgs) as void:
		SwapBuffers()
		# update counter
		if fps.update(Time):
			Title = fps.gen()
		# redraw views
		for v in views:
			v.update()
