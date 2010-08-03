namespace kri

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics


public class Config:
	private final dict	= Collections.Generic.Dictionary[of string,string]()
	public def constructor():
		pass
	public def read(path as string) as void:
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


#-----------------------------------------------------------#
#			APPWINDOW = window calls wrapper				#
#-----------------------------------------------------------#

public class Window( GameWindow ):
	public final views	= List[of View]()	# *View
	public final core	as Ant				# KRI Core
	private final fps	as FpsCounter		# FPS counter
	
	public PointerNdc as Vector3:
		get: return Vector3.Multiply( Vector3(
			0f + Mouse.X*1f / Width,
			1f - Mouse.Y*1f / Height,
			0f ), 2f) - Vector3.One

	public def constructor(cPath as string, depth as int):
		# read config
		(conf = Config()).read(cPath)
		title	= conf.ask('Title','kri')
		sizes	= conf.ask('Window','0x0').Split(char('x'))
		context	= conf.ask('Context','0')
		bug = context.EndsWith('d')
		ver = uint.Parse( context.TrimEnd(*'rd'.ToCharArray()) )
		wid	= uint.Parse( sizes[0] )
		het	= uint.Parse( sizes[1] )
		period	= single.Parse( conf.ask('StatPeriod','1.0') )

		# prepare attributes
		dd = DisplayDevice.Default
		gm = GraphicsMode( ColorFormat(8), depth, 0 )
		conFlags  = GraphicsContextFlags.ForwardCompatible
		conFlags |= GraphicsContextFlags.Debug	if bug
		gameFlags  = GameWindowFlags.Default
		gameFlags |= GameWindowFlags.Fullscreen	if wid+het==0
		wid = dd.Width	if not wid
		het = dd.Height	if not het

		# start
		super(wid,het, gm, title, gameFlags, dd, 3,ver, conFlags)
		core = Ant(conf,bug)
		fps = FpsCounter(period,title)
		

	public override def Dispose() as void:
		views.Clear()
		(core as IDisposable).Dispose()
		super()
	
	public override def OnResize(e as EventArgs) as void:
		for v in views:
			continue	if v.resize(Width,Height)
			raise 'View resize fail!'
	
	public override def OnUpdateFrame(e as FrameEventArgs) as void:
		core.update()

	public override def OnRenderFrame(e as FrameEventArgs) as void:
		SwapBuffers()
		# update counter
		if fps.update(core.Time):
			Title = fps.gen()
		# redraw views
		for v in views:
			v.update()


#-----------------------------------------------------------#
#			ANT = kri engine core							#
#-----------------------------------------------------------#

public interface IExtension:
	def attach(nt as load.Native) as void


public class Ant(IDisposable):
	[getter(Inst)]
	public static inst	as Ant = null		# Singleton
	# context
	public final caps	= lib.Capabilities()	# Render capabilities
	public final debug	as bool					# is debug context
	public final quad	as kri.kit.gen.Frame	# Standard quad
	# time
	private final sw	= Diagnostics.Stopwatch()	# Time counter
	public anim	as ani.IBase	= null		# Animation
	public Time as double:
		get: return sw.Elapsed.TotalSeconds
	
	# Slots
	public final slotTechniques	= lib.Slot( 24 )
	public final slotAttributes	= lib.Slot( caps.vertexAttribs )
	public final slotParticles	= lib.Slot( caps.vertexAttribs )
	
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


	public def constructor(conf as Config, bug as bool):
		# config read
		defPath = '../../engine/shader'
		if conf:
			defPath	= conf.ask('ShaderPath',defPath)
			# check configuration completeness
			unused = array( conf.getUnused() )
			if unused.Length:
				raise 'Unknown config parameter: ' + unused[0]
		
		# context init
		kri.rend.Context.Init()
		shade.Code.Folder = defPath

		inst = self
		sw.Start()
		debug = bug
		quad = kri.kit.gen.Frame( kri.kit.gen.Quad() )
		
		# shader library init
		resMan.register( shade.Loader() )
		libShaders = array( resMan.load[of kri.shade.Object]('/lib/'+str)
			for str in ('quat_v','tool_v','orient_v','fixed_v','math_f'))
		# extensions init
		loaders = load.Standard()
		extensions.Add(loaders)
		
	def IDisposable.Dispose() as void:
		inst = null
		resMan.clear()
		extensions.Clear()
		sw.Stop()
		GC.Collect()
		GC.WaitForPendingFinalizers()

	public def update() as void:
		tc = Time; old = params.parTime.Value.X
		params.parTime.Value = Vector4(tc, tc-old, 0f,0f)
		anim = null	if anim and anim.onFrame(Time)
