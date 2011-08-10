namespace kri

import System
import System.Collections.Generic
import OpenTK


#-----------------------------------------------------------#
#			WINDOW = opengl window calls wrapper			#
#-----------------------------------------------------------#

public class Window( GameWindow ):
	public final views	= List[of IView]()	# *View
	public final ticks	as uint				# Ticks per frame
	public final core	as Ant				# KRI Core
	private final fps	as FpsCounter		# FPS counter
	
	public PointerNdc as Vector3:
		get: return Vector3.Multiply( Vector3(
			0f + Mouse.X*1f / Width,
			1f - Mouse.Y*1f / Height,
			0f ), 2f) - Vector3.One

	public def constructor(cPath as string, depth as int):
		# read config
		conf = lib.Config(cPath)
		title	= conf.ask('Title','kri')
		sizes	= conf.ask('Window','0x0').Split(char('x'))
		wid	= uint.Parse( sizes[0] )
		het	= uint.Parse( sizes[1] )
		opt = lib.OptionReader(conf)

		# prepare attributes
		dd = DisplayDevice.Default
		gameFlags  = GameWindowFlags.Default
		gameFlags |= GameWindowFlags.Fullscreen	if wid+het==0
		if not wid:	wid = dd.Width
		if not het:	het = dd.Height
		gmode = opt.genMode(32,depth)
		flags = opt.genFlags()

		# start
		super(wid,het, gmode, title, gameFlags, dd, opt.verMajor, opt.verMinor, flags)
		ticks	= uint.Parse(	conf.ask('FrameTicks','0') )
		period	= single.Parse(	conf.ask('StatPeriod','1.0') )
		fps = FpsCounter(period,title)
		core = Ant( conf, opt.debug, opt.gamma )
		

	public override def Dispose() as void:
		views.Clear()
		(core as IDisposable).Dispose()
		GC.Collect()
		GC.WaitForPendingFinalizers()
		super()
	
	public override def OnResize(e as EventArgs) as void:
		for v in views:
			if v.resize(Width,Height): continue
			lib.Journal.Log("Resize: failed on view (${v})")
	
	public override def OnUpdateFrame(e as FrameEventArgs) as void:
		core.update( (1,0)[ticks] )

	public override def OnRenderFrame(e as FrameEventArgs) as void:
		SwapBuffers()
		# update animations
		core.update(ticks)
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
	private static inst	as Ant = null		# Singleton
	# context
	public final caps	= lib.Capabilities(true)	# Render capabilities
	public final debug	as bool						# is debug context
	public final gamma	as bool						# is gamma corrected
	public final quad	as gen.Frame	= null		# Standard quad frame
	# time
	private final sw	= Diagnostics.Stopwatch()	# Time counter
	public anim	as ani.IBase	= null		# Animation
	public Time as double:
		get: return sw.Elapsed.TotalSeconds
	
	# techniques
	public final techniques	= Dictionary[of string,rend.Basic]()
	# extensions
	public final extensions	= List[of IExtension]()
	public final loaders	as load.Standard
	# resource manager
	public final dataMan	= data.Manager()
	# main uniform dictionary
	public final dict		= shade.par.Dict()
	# libraries
	public final params		= lib.Param(dict)
	public final libShaders	as (kri.shade.Object)


	public def constructor(conf as lib.Config, bug as bool, gammaCorr as bool):
		# config read
		defPath = '../../gpu'
		answers = ('no','yes')
		feedCount	= answers[kri.TransFeedback.CountPrimitives]
		safeDiscard	= answers[kri.Discarder.Safe]
		if conf:
			defPath		= conf.ask('ShaderPath',defPath)
			feedCount	= conf.ask('FeedbackCount',feedCount)
			safeDiscard	= conf.ask('SafeDiscard',safeDiscard)
			# check configuration completeness
			unused = List[of string]( conf.getUnused() ).ToArray()
			if unused.Length:
				str = string.Join(',',unused)
				lib.Journal.Log("Cmd: unknown parameters (${str})")
		
		# context init
		kri.rend.link.Basic.Init()
		shade.Code.Folder = defPath
		TransFeedback.CountPrimitives = (feedCount	== answers[1])
		Discarder.Safe = (safeDiscard				== answers[1])

		inst = self
		sw.Start()
		debug = bug
		gamma = gammaCorr
		quad = gen.Frame( 'quad', gen.Quad() )
		
		# shader library init
		dataMan.register( shade.Loader() )
		libShaders = List[of shade.Object]( dataMan.load[of shade.Object]('/lib/'+s)
			for s in ('quat_v','tool_v','orient_v','fixed_v','math_f')).ToArray()
		# extensions init
		loaders = load.Standard()
		extensions.Add(loaders)
		
	def IDisposable.Dispose() as void:
		inst = null
		kri.TransFeedback.Bind()
		dataMan.clear()
		extensions.Clear()
		sw.Stop()

	public def update(ticks as uint) as void:
		cur = params.parTime.Value.Z
		tc = Time
		for i in range(ticks):
			add = ((tc-cur)/ ticks, tc-cur)[i+1==ticks]
			dt = 1f / Math.Max(0.001f, add)
			cur += add
			params.parTime.Value = Vector4(add,cur,cur,dt)
			if anim and anim.onFrame(cur):
				anim = null
