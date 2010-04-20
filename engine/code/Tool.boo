namespace kri

import System
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL

# Generic structures size calculator

public static class Sizer[of T(struct)]:
	public final Value = Runtime.InteropServices.Marshal.SizeOf(T)

public interface IGenerator[of T]:
	def generate() as T

public def swap[of T](ref a as T, ref b as T) as void:
	a,b = b,a

# Provides GL state on/off mechanics
public class Section(IDisposable):
	private final cap as EnableCap
	public def constructor(state as EnableCap):
		cap = state
		assert not GL.IsEnabled(cap)
		GL.Enable(cap)
	public virtual def Dispose() as void:
		assert GL.IsEnabled(cap)
		GL.Disable(cap)


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
	public virtual def Dispose() as void:
		if safe:
			GL.ColorMask(true,true,true,true)
		super()


# Provides skipping of resource unloading errors on exit
public def safeKill(fun as callable() as void) as void:
	try: fun()
	except e as GraphicsContextMissingException:
		pass

# Window FPS counter
public class FpsCounter:
	public final kPeriod	as double
	private kNext 	= 0.0
	private kPrev	= 0.0
	private fMean	= 0.0
	private fDisp	= 0.0
	private nFrames	= 0.0
	# interface
	public def constructor(per as double):
		kPeriod = kNext = per
	public def update(moment as Double) as bool:
		t = moment - kPrev
		kPrev += t
		fMean += t
		fDisp += t*t
		nFrames += 1.0
		return moment > kNext
	public def gen() as string:
		fMean /= nFrames
		fDisp = Math.Sqrt(fDisp / nFrames - fMean*fMean)
		rez = "kri: {0,6:f3} mean, {1,6:f3} disp" % (fMean,fDisp)
		fMean = fDisp = nFrames = 0.0
		kNext += kPeriod
		return rez


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
		safeKill({ GL.DeleteQueries(1,tmp) })
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
	public final mode	as BeginFeedbackMode
	public def constructor(nv as byte):
		super( QueryTarget.TransformFeedbackPrimitivesWritten )
		mode = (BeginFeedbackMode.Points, BeginFeedbackMode.Lines, BeginFeedbackMode.Triangles)[nv-1]
	public override def catch() as Catcher:
		return CatcherFeed(self,mode)
	# could be static, but it would make no sence
	public static def Setup(prog as shade.Program, separate as bool, *vars as (string)) as void:
		GL.TransformFeedbackVaryings( prog.id, vars.Length, vars,
			(TransformFeedbackMode.InterleavedAttribs,TransformFeedbackMode.SeparateAttribs)[separate] )
	public static def Bind(*buffers as (vb.Object)) as void:
		for i as uint in range( buffers.Length ):
			GL.BindBufferBase( BufferTarget.TransformFeedbackBuffer, i, buffers[i].Extract )
