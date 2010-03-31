namespace kri.load.image

import OpenTK.Graphics.OpenGL

#------		BASIC RGBA IMAGE		------#

public class Basic:
	public final name	as string
	public final width	as int
	public final height	as int
	public final scan 	as (byte)
	public static bRepeat	= false
	public static bMipMap	= true
	public static bFilter	= true
	
	public def constructor(s as string, w as int, h as int):
		name,width,height,scan = s,w,h, array[of byte](w*h<<2)
	public def generate() as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.Name = name
		tex.bind()
		kri.Texture.Filter(bFilter,bMipMap)
		wm = (TextureWrapMode.Repeat if bRepeat else TextureWrapMode.ClampToBorder)
		kri.Texture.Wrap(wm,2)
		kri.Texture.Init(width,height, PixelInternalFormat.Rgba8, scan)
		kri.Texture.GenLevels()	if bMipMap
		return tex
