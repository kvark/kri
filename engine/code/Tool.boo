namespace kri

import System
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL

# Generic structures size calculator

public static class Sizer[of T(struct)]:
	public final Value = Runtime.InteropServices.Marshal.SizeOf(T)


# Provides GL state on/off mechanics
public class Section(IDisposable):
	private final cap as EnableCap
	public def constructor(state as EnableCap):
		cap = state
		assert not GL.IsEnabled(cap)
		GL.Enable(cap)
	def IDisposable.Dispose() as void:
		assert GL.IsEnabled(cap)
		GL.Disable(cap)


# Provide standard blending options
public class Blender(Section):
	public def constructor():
		super( EnableCap.Blend )
	public static def alpha(alpha as single) as void:
		GL.BlendColor(0f,0f,0f, alpha)
	public static def add() as void:
		GL.BlendFunc(BlendingFactorSrc.One, BlendingFactorDest.One)
	public static def over() as void:
		GL.BlendFunc(BlendingFactorSrc.One, BlendingFactorDest.Zero)
	public static def skip() as void:
		GL.BlendFunc(BlendingFactorSrc.Zero, BlendingFactorDest.One)
	public static def multiply() as void:
		GL.BlendFunc(BlendingFactorSrc.DstColor, BlendingFactorDest.Zero)
	public static def overAlpha() as void:
		GL.BlendFunc(BlendingFactorSrc.One, BlendingFactorDest.ConstantAlpha)
	public static def skipAlpha() as void:
		GL.BlendFunc(BlendingFactorSrc.ConstantAlpha, BlendingFactorDest.One)


# Provide standard blending options
public class Discarder(Section):
	public def constructor():
		super( EnableCap.RasterizerDiscard )


# Provides skipping of resource unloading errors on exit
public def SafeKill(fun as callable() as void) as void:
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


#-----------------------#
#	TRANSFORM FEEDBACK	#
#-----------------------#

private class FeedCatch(IDisposable):
	public static safe = true
	public def constructor(q as int):
		if safe:
			GL.PointSize(1.0)
			GL.ColorMask(false,false,false,false)
			GL.Disable( EnableCap.DepthTest )
		GL.BeginTransformFeedback( BeginFeedbackMode.Points )
		GL.BeginQuery( QueryTarget.TransformFeedbackPrimitivesWritten, q )
	def IDisposable.Dispose():
		GL.EndQuery( QueryTarget.TransformFeedbackPrimitivesWritten )
		GL.EndTransformFeedback()
		if safe:
			GL.ColorMask(true,true,true,true)
	

public class TransFeedback:
	private final query	as int
	public def constructor():
		tmp = 0
		GL.GenQueries(1,tmp)
		query = tmp
	public def catch() as FeedCatch:
		return FeedCatch(query)
	public def result() as int:
		rez = 0
		GL.GetQueryObject(query, GetQueryObjectParam.QueryResult, rez)
		return rez
	public static def setup(prog as shade.Program, separate as bool, *vars as (string)) as void:
		GL.TransformFeedbackVaryings(prog.id, vars.Length, vars,
			(TransformFeedbackMode.SeparateAttribs if separate else TransformFeedbackMode.InterleavedAttribs)
			)
	public static def bind(*buffers as (vb.Object)) as void:
		for i in range(buffers.Length):
			GL.BindBufferBase(BufferTarget.TransformFeedbackBuffer, i, buffers[i].Extract)
