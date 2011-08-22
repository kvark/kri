namespace kri

import System
import OpenTK.Graphics.OpenGL

# Generic structures size calculator

public static class Sizer[of T(struct)]:
	public final Value = System.Runtime.InteropServices.Marshal.SizeOf(T)


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
	public final	cap as EnableCap
	public final	dir	as bool
	
	public def switch(val as bool) as void:
		on = (val == dir)
		if on == GL.IsEnabled(cap):
			lib.Journal.Log("GL: unexpected state (${cap} == ${not on})")
		if on:	GL.Enable(cap)
		else:	GL.Disable(cap)
			
	public def constructor(state as EnableCap, direct as bool):
		cap = state
		dir = direct
		switch(true)
	
	public def constructor(state as EnableCap):
		self(state,true)
		
	public virtual def Dispose() as void:  #imp: IDisposable
		switch(false)


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
