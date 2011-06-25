namespace kri

import System
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
		if OpenTK.Graphics.GraphicsContext.CurrentContext:
			fun()
	# semantics fill helper
	public def enrich(ob as vb.ISemanted, size as byte, *names as (string)) as void:
		for str in names:
			ob.Semant.Add( vb.Info(
				name:str, size:size, integer:false,
				type:VertexAttribPointerType.Float ))
	# smart logical shift
	public def shiftInt(val as int, shift as int) as int:
		return (val<<shift	if shift>0 else val>>-shift)
	# copy dictionary
	public def copyDic[of K,V](dv as (Collections.Generic.Dictionary[of K,V])) as void:
		for x in dv[1]:
			dv[0].Add( x.Key, x.Value )


#---------------#
#	GL Caps		#
#---------------#

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
		GL.BlendEquation( BlendEquationMode.FuncAdd )
	public Alpha as single:
		set: GL.BlendColor(0f,0f,0f, value)
	public static def min() as void:
		GL.BlendEquation( BlendEquationMode.Min )
		GL.BlendFunc( BlendingFactorSrc.One,			BlendingFactorDest.One )
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
	public static Safe	= false
	public def constructor():
		super( EnableCap.RasterizerDiscard )
		if Safe:
			GL.PointSize(1.0)
			GL.ColorMask(false,false,false,false)
			GL.Disable( EnableCap.DepthTest )
	public override def Dispose() as void:
		if Safe:
			GL.ColorMask(true,true,true,true)
		super()
