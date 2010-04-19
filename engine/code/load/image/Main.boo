namespace kri.load.image

import OpenTK.Graphics.OpenGL

#------		BASIC RGBA IMAGE		------#

public class Basic( kri.IGenerator[of kri.Texture] ):
	public final name	as string
	public final width	as int
	public final height	as int
	public final scan 	as (byte)
	public static bRepeat	= false
	public static bMipMap	= true
	public static bFilter	= true
	public format	= PixelFormat.Rgba
	
	public def constructor(s as string, w as uint, h as uint, d as byte):
		name,width,height,scan = s,w,h, array[of byte](w*h*d)
	public def constructor(s as string, w as uint, h as uint, ar as (byte), fm as PixelFormat):
		name,width,height,scan,format = s,w,h,ar,fm
	public def generate() as kri.Texture:	# IGenerator
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.Name = name
		tex.bind()
		kri.Texture.Filter(bFilter,bMipMap)
		wm = (TextureWrapMode.Repeat if bRepeat else TextureWrapMode.ClampToBorder)
		kri.Texture.Wrap(wm,2)
		GL.TexImage2D( tex.type,0, PixelInternalFormat.Rgba8, width,height,0,\
			format, PixelType.UnsignedByte, scan )
		#kri.Texture.Init(width,height, pif, scan)
		kri.Texture.GenLevels()	if bMipMap
		return tex
