namespace kri

import System
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL

# Generic structures size calculator

public static class Sizer[of T(struct)]:
	public final Value = System.Runtime.InteropServices.Marshal.SizeOf(T)


# Window FPS counter
public class FpsCounter:
	public final kPeriod	as double
	public final title		as string
	private kNext 	= 0.0
	private kPrev	= 0.0
	private fSum	= 0.0
	private fMax	= 0.0
	private nFrames	= 0.0
	# interface
	public def constructor(per as double, name as string):
		kPeriod = kNext = per
		title = name
	public def update(moment as Double) as bool:
		return false	if kPeriod<=0.0
		t = moment - kPrev
		kPrev += t
		fSum += t
		fMax = Math.Max(fMax,t)
		nFrames += 1.0
		return moment > kNext
	public def gen() as string:
		avg = fSum / nFrames
		fps = nFrames / kPeriod
		stats = '{0,4} fps, {1,6:f4} avg, {2,6:f4} max'
		rez = "${title}: ${stats}" % (fps,avg,fMax)
		fSum = fMax = nFrames = 0.0
		kNext += kPeriod
		return rez


#-----------#
#	HELP	#
#-----------#

public static class Help:
	# swap two abstract elements
	public def swap[of T](ref a as T, ref b as T) as void:
		a,b = b,a
	# provides skipping of resource unloading errors on exit
	public def safeKill(fun as callable() as void) as void:
		try: fun()
		except e as GraphicsContextMissingException:
			pass
	# semantics fill helper
	public def enrich(ob as vb.ISemanted, size as byte, *names as (string)) as void:
		for str in names:
			ob.Semant.Add( vb.Info(
				name:str, size:size, integer:false,
				type:VertexAttribPointerType.Float ))
	# get integer state value
	public def getInteger( pn as GetPName ) as int:
		rez = -1
		GL.GetInteger(pn,rez)
		return rez
	# smart logical shift
	public def shiftInt(val as int, shift as int) as int:
		return (val<<shift	if shift>0 else val>>-shift)


# Provides GL state on/off mechanics
public class Section(IDisposable):
	private final cap as EnableCap
	public def constructor(state as EnableCap):
		cap = state
		assert not GL.IsEnabled(cap)
		GL.Enable(cap)
	public virtual def Dispose() as void:  #imp: IDisposable
		assert GL.IsEnabled(cap)
		GL.Disable(cap)

public class SectionOff(IDisposable):
	private final cap as EnableCap
	public def constructor(state as EnableCap):
		cap = state
		assert GL.IsEnabled(cap)
		GL.Disable(cap)
	def IDisposable.Dispose() as void:
		assert not GL.IsEnabled(cap)
		GL.Enable(cap)


# Provide standard blending options
public class Blender(Section):
	public def constructor():
		super( EnableCap.Blend )
	public Alpha as single:
		set: GL.BlendColor(0f,0f,0f, value)
	public static def alpha() as void:
		GL.BlendFunc( BlendingFactorSrc.SrcAlpha,		BlendingFactorDest.OneMinusSrcAlpha )
	public static def add() as void:
		GL.BlendFunc( BlendingFactorSrc.One,			BlendingFactorDest.One )
	public static def over() as void:
		GL.BlendFunc( BlendingFactorSrc.One,			BlendingFactorDest.Zero )
	public static def skip() as void:
		GL.BlendFunc( BlendingFactorSrc.Zero,			BlendingFactorDest.One )
	public static def multiply() as void:
		GL.BlendFunc( BlendingFactorSrc.DstColor,		BlendingFactorDest.Zero )
	public static def overAlpha() as void:
		GL.BlendFunc( BlendingFactorSrc.One,			BlendingFactorDest.ConstantAlpha )
	public static def skipAlpha() as void:
		GL.BlendFunc( BlendingFactorSrc.ConstantAlpha,	BlendingFactorDest.One )


# Provide standard blending options
public class Discarder(Section):
	public final safe	as bool
	public def constructor(safety as bool):
		super( EnableCap.RasterizerDiscard )
		safe = safety
		if safe:
			GL.PointSize(1.0)
			GL.ColorMask(false,false,false,false)
			GL.Disable( EnableCap.DepthTest )
	public override def Dispose() as void:
		if safe:
			GL.ColorMask(true,true,true,true)
		super()

#-----------#
#	QUERY	#
#-----------#

public class Catcher(IDisposable):
	public final t	as QueryTarget
	public def constructor(q as Query):
		t = q.target
		GL.BeginQuery( t, q.qid )
	public virtual def Dispose() as void:
		GL.EndQuery(t)

public class Query:
	public final qid	as int
	public final target	as QueryTarget
	public def constructor( targ as QueryTarget ):
		tmp = 0
		GL.GenQueries(1,tmp)
		qid,target = tmp,targ
	def destructor():
		tmp = qid
		Help.safeKill({ GL.DeleteQueries(1,tmp) })
	public virtual def catch() as Catcher:
		return Catcher(self)
	public def result() as int:
		rez = 0
		GL.GetQueryObject(qid, GetQueryObjectParam.QueryResult, rez)
		return rez


#-----------------------#
#	TRANSFORM FEEDBACK	#
#-----------------------#

public class CatcherFeed(Catcher):
	public def constructor(q as Query, m as BeginFeedbackMode):
		GL.BeginTransformFeedback(m)
		super(q)
	public override def Dispose() as void:
		super()
		GL.EndTransformFeedback()

public class TransFeedback(Query):
	public final	mode	as BeginFeedbackMode
	public static	final	Cache	= array[of vb.Object](8)
	public def constructor(nv as byte):
		super( QueryTarget.TransformFeedbackPrimitivesWritten )
		mode = (BeginFeedbackMode.Points, BeginFeedbackMode.Lines, BeginFeedbackMode.Triangles)[nv-1]
	public override def catch() as Catcher:
		return CatcherFeed(self,mode)
	public static def Bind(*buffers as (vb.Object)) as bool:
		for i as uint in range( buffers.Length ):
			bf = Cache[i] = buffers[i]
			if not bf.Ready:
				return false
			GL.BindBufferBase( BufferTarget.TransformFeedbackBuffer, i, bf.handle )
		for i in range( buffers.Length, Cache.Length ):
			Cache[i] = null
		return true
