namespace kri.gen

import OpenTK.Graphics.OpenGL

public static class Texture:
	private def make() as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.bind()
		kri.Texture.Filter(false,false)
		return tex
	
	public def raw(*data as (byte)) as kri.Texture:
		tex = make()
		GL.TexImage2D( tex.target, 0, PixelInternalFormat.Rgba8, 1,1,0,\
			PixelFormat.Rgba, PixelType.UnsignedByte, data )
		return tex
	public def raw(val as single) as kri.Texture:
		tex = make()
		GL.TexImage2D( tex.target, 0, PixelInternalFormat.DepthComponent, 1,1,0,\
			PixelFormat.DepthComponent, PixelType.Float, (val,) )
		return tex
	
	public final color	= raw(0xFF,0xFF,0xFF,0xFF)
	public final normal	= raw(0x80,0x80,0xFF,0x80)
	public final depth	= raw(1f)
