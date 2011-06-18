namespace kri.load.image

import OpenTK.Graphics.OpenGL

#------		BASIC RGBA IMAGE		------#

public class Basic( kri.data.IGenerator[of kri.buf.Texture] ):
	public final name	as string
	public final width	as uint
	public final height	as uint
	public final scan 	as (byte)
	public final bits	as byte
	public static	IntFormat	= PixelInternalFormat.Rgba
	
	public static Compressed as bool:
		get: return IntFormat == PixelInternalFormat.CompressedRgba
		set: IntFormat = (PixelInternalFormat.Rgba,PixelInternalFormat.CompressedRgba)[value]
	
	public def constructor(s as string, w as uint, h as uint, d as byte):
		name = s
		width,height = w,h
		scan = array[of byte](w*h*d)
		bits = d<<3
	
	public def constructor(s as string, w as uint, h as uint, ar as (byte), d as byte):
		name = s
		width,height = w,h
		scan = ar
		bits = d<<3
	
	public def getFormat() as PixelFormat:
		pa = PixelFormat.Alpha
		return (pa,pa,pa, PixelFormat.Bgr, PixelFormat.Bgra)[bits>>3]
	
	public def generate() as kri.buf.Texture:	#imp: kri.res.IGenerator
		tex = kri.buf.Texture( wid:width, het:height,
			name:name, pixFormat:getFormat(), intFormat:IntFormat )
		tex.init(scan)
		return tex
