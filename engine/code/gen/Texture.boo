namespace kri.gen

import System
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


public static class Texture:
	public struct Key:
		public pos	as single
		public col	as Color4
	
	public final border = Color4.Black
	
	private def make() as kri.buf.Texture:
		tex = kri.buf.Texture()
		tex.setState(0,false,false)
		return tex
	
	public def ofColor(*data as (byte)) as kri.buf.Texture:
		tex = kri.buf.Texture( wid:1, het:1 )
		tex.init(data)
		return tex
	public def ofDepth(val as single) as kri.buf.Texture:
		tex = kri.buf.Texture( wid:1, het:1,
			intFormat:PixelInternalFormat.DepthComponent,
			pixFormat:PixelFormat.DepthComponent )
		tex.init((val,))
		return tex

	
	public def ofCurve(data as (Key)) as kri.buf.Texture:
		assert data.Length
		mid = 1f
		for i in range( data.Length-1 ):
			mid = Math.Min(mid, data[i+1].pos - data[i].pos)
		assert mid>0f
		d2 = array[of Color4](1 + cast(int, 1f / mid))
		mid = 1f / (d2.Length-1)
		for i in range(d2.Length):
			t = i * mid
			j = 0
			while(j!=data.Length and data[j].pos<t):
				j += 1
			if j==0:
				d2[i] = kri.load.ExAnim.InterColor(
					border, data[j].col, t / data[j].pos)
			elif j==data.Length:
				d2[i] = kri.load.ExAnim.InterColor(
					data[j-1].col, border, 1f - (1f-t) / (1f-data[j-1].pos))
			else:
				d2[i] = kri.load.ExAnim.InterColor(
					data[j-1].col, data[j].col,
					(t-data[j-1].pos) / (data[j].pos - data[j-1].pos))
		tex = kri.buf.Texture( target:TextureTarget.Texture1D, wid:d2.Length )
		tex.setState(0,true,true)
		tex.init(d2)
		return tex

	
	public final color	= ofColor(0xFF,0xFF,0xFF,0xFF)
	public final normal	= ofColor(0x80,0x80,0xFF,0x80)
	public final depth	= ofDepth(1f)
	public final noise	= ofColor(0,0,0,0)
