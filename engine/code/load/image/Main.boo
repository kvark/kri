namespace kri.load.image

import OpenTK.Graphics.OpenGL

#------		BASIC RGBA IMAGE		------#

public class Basic( kri.res.IGenerator[of kri.Texture] ):
	public final name	as string
	public final width	as uint
	public final height	as uint
	public final scan 	as (byte)
	public final bits	as byte
	
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
	
	public def generate() as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.Name = name
		tex.bind()
		GL.TexImage2D( tex.type,0, PixelInternalFormat.Rgba8, width,height,0,\
			getFormat(), PixelType.UnsignedByte, scan )
		#kri.Texture.Init(width,height, pif, scan)
		return tex
