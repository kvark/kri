namespace kri

import OpenTK.Graphics.OpenGL


#---	format conversion arrays	---#

internal static class Fm:
	public final bad		= PixelInternalFormat.Alpha
	public final stencil	= PixelInternalFormat.Depth24Stencil8
	public final depth	= (of PixelInternalFormat:
		PixelInternalFormat.DepthComponent,
		PixelInternalFormat.Depth24Stencil8,
		PixelInternalFormat.DepthComponent16,
		PixelInternalFormat.DepthComponent24,
		PixelInternalFormat.DepthComponent32
	)
	public final color	= (of PixelInternalFormat:
		PixelInternalFormat.Rgba,
		PixelInternalFormat.Rgba8,
		PixelInternalFormat.Rgba16f,
		bad,
		PixelInternalFormat.Rgba32f
	)
	public final index	= (of PixelInternalFormat:
		bad,
		PixelInternalFormat.R8,
		PixelInternalFormat.R16,
		bad,bad
	)
	public final index2	= (of PixelInternalFormat:
		bad,
		PixelInternalFormat.Rg8,
		PixelInternalFormat.Rg16,
		bad,bad
	)


#---	General Texture class	---#

public class Texture( shade.par.INamed ):
	public enum Class:
		Color
		Depth
		Stencil
		Index
		Index2
		Other
	private static curTarget	as TextureTarget = TextureTarget.Texture1D
	private static final zeroPtr	= System.IntPtr.Zero
	public final target	as TextureTarget
	public final id		as int
	[Property(Name)]
	private name		as string	= ''

	public def constructor(targ as TextureTarget):
		id = GL.GenTexture()
		target = targ
	def destructor():
		Help.safeKill({ GL.DeleteTexture(id) })

	public static def Slot(tun as int) as void:
		GL.ActiveTexture( TextureUnit.Texture0 + tun )
	public static def Unbind() as void:
		GL.BindTexture( curTarget, 0 )
	public def bind() as void:
		GL.BindTexture( curTarget=target, id )
	public def bind(tun as int) as void:
		Slot(tun)
		bind()
	
	# set filtering mode: point/linear
	public static def Filter(mode as bool, mips as bool) as void:
		vMin as TextureMinFilter
		vMag = ( TextureMagFilter.Linear if mode else TextureMagFilter.Nearest )
		if mips:
			if mode	: vMin = TextureMinFilter.LinearMipmapLinear
			else	: vMin = TextureMinFilter.NearestMipmapNearest
		else:
			if mode	: vMin = TextureMinFilter.Linear
			else	: vMin = TextureMinFilter.Nearest
		val = (of int: cast(int,vMin), cast(int,vMag))
		GL.TexParameter( curTarget, TextureParameterName.TextureMinFilter, val[0] )
		GL.TexParameter( curTarget, TextureParameterName.TextureMagFilter, val[1] )
	
	# set wrapping mode: clamp/repeat
	public static def Wrap(mode as TextureWrapMode, dim as int) as void:
		val = cast(int,mode)
		wraps = (TextureParameterName.TextureWrapS, TextureParameterName.TextureWrapT, TextureParameterName.TextureWrapR)
		assert dim>=0 and dim<wraps.Length
		for wp in wraps[0:dim]:
			GL.TexParameterI(curTarget, wp, val)

	# set shadow mode: on/off
	public static def Shadow(en as bool) as void:
		param = 0
		if en:
			param = cast(int, TextureCompareMode.CompareRefToTexture)
			func = cast(int, DepthFunction.Lequal)
			GL.TexParameterI( curTarget, TextureParameterName.TextureCompareFunc, func )
		if 'always':
			GL.TexParameterI( curTarget, TextureParameterName.TextureCompareMode, param )
		
	# generate mipmaps
	public static def GenLevels() as void:
		assert curTarget != TextureTarget.TextureRectangle
		ti = cast(GenerateMipmapTarget, cast(int,curTarget))
		GL.GenerateMipmap(ti)
	
	# select a range of LODs to sample from
	public static def SetLevels(a as int, b as int) as void:
		GL.TexParameterI( curTarget, TextureParameterName.TextureBaseLevel, a )	if a>=0
		GL.TexParameterI( curTarget, TextureParameterName.TextureMaxLevel, b )	if b>=0
	
	# auxilary methods for init
	private static def Fi2format(fi as PixelInternalFormat) as PixelFormat:
		return PixelFormat.DepthStencil		if fi == Fm.stencil
		return PixelFormat.DepthComponent	if fi in Fm.depth
		return PixelFormat.Red				if fi in Fm.index
		return PixelFormat.Rg				if fi in Fm.index2
		return PixelFormat.Rgba
	private static def Fi2type(fi as PixelInternalFormat) as PixelType:
		return PixelType.UnsignedInt248	if fi == Fm.stencil
		return PixelType.UnsignedByte	if fi in (Fm.color[:2] + Fm.index[:2] + Fm.index2[:2])
		return PixelType.UnsignedShort	if fi in ( Fm.index[2], Fm.index2[2] )
		return PixelType.UnsignedInt	if fi in ( Fm.index[4], Fm.index2[4] )
		return PixelType.Float
	
	public static def AskFormat(cl as Class, bits as uint) as PixelInternalFormat:
		d = bits>>3
		return Fm.color[d]	if cl == Class.Color
		return Fm.depth[d]	if cl == Class.Depth
		return Fm.stencil	if cl == Class.Stencil
		return Fm.index[d]	if cl == Class.Index
		return Fm.index2[d]	if cl == Class.Index2
		return Fm.bad
	private static def curTargetMulti() as TextureTargetMultisample:
		return cast( TextureTargetMultisample, cast(int,curTarget) )

	# init Texture2D/3D/Array format
	public static def Init(fi as PixelInternalFormat, sx as int, sy as int, sz as int) as void:
		assert fi != Fm.bad
		fmt = Fi2format(fi)
		type = Fi2type(fi)
		if sz>0:	GL.TexImage3D(curTarget, 0, fi, sx, sy, sz,	0, fmt, type, zeroPtr)
		else:		GL.TexImage2D(curTarget, 0, fi, sx, sy,		0, fmt, type, zeroPtr)
	# init VBO link
	public static def Init(sif as SizedInternalFormat, buf as kri.vb.Object) as void:
		GL.TexBuffer( TextureBufferTarget.TextureBuffer, sif, buf.Extract )
		
	# init depth array format
	public static def InitDepthArray(sx as int, sy as int, sz as int) as void:
		Init( Fm.depth[0], sx,sy,sz )
		Shadow(true)
	
	# init multi-sampled texture
	public static def InitMulti(fi as PixelInternalFormat, samples as byte, fixedLoc as bool, sx as int, sy as int, sz as int) as void:
		if not samples:	Init(fi,sx,sy,sz)
		elif sz>0:	GL.TexImage3DMultisample( curTargetMulti(), samples, fi, sx, sy, sz,	fixedLoc )
		else:		GL.TexImage2DMultisample( curTargetMulti(), samples, fi, sx, sy, 		fixedLoc )
	
	# init cube map format
	public static def InitCube(fi as PixelInternalFormat, siz as int) as void:
		format,pixtype = Fi2format(fi),Fi2type(fi)
		for t in (
			TextureTarget.TextureCubeMapNegativeX,	TextureTarget.TextureCubeMapPositiveX,
			TextureTarget.TextureCubeMapNegativeY,	TextureTarget.TextureCubeMapPositiveY,
			TextureTarget.TextureCubeMapNegativeZ,	TextureTarget.TextureCubeMapPositiveZ):
			GL.TexImage2D(t, 0, fi, siz, siz, 0, format, pixtype, zeroPtr)
