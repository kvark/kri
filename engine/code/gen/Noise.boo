namespace kri.gen

import OpenTK.Graphics.OpenGL
import kri.shade

public class Noise:
	private final targ	= TextureTarget.Texture1D
	private final tPerm	= par.Texture('perm')
	private final tGrad	= par.Texture('grad')
	public final dict	= rep.Dict()
	public final sh_simplex	= Object.Load('/gen/noise_f')
	public final sh_turbo	= Object.Load('/gen/turbo_f')
	public final sh_tile	= Object.Load('/gen/tile_f')

	public def constructor(order as byte):
		dict.unit(tPerm,tGrad)
		# create textures
		for pt in (tPerm,tGrad):
			pt.Value = kri.buf.Texture( target:targ )
			pt.Value.setState(1,false,false)
		# init permutations
		generate(order)	if order
		# init gradient
		tGrad.Value.bind()
		data = (of single:
			1f,1f,0f, -1f,1f,0f, 1f,-1f,0f, -1f,-1f,0f,
			1f,0f,1f, -1f,0f,1f, 1f,0f,-1f, -1f,0f,-1f,
			0f,1f,1f, 0f,-1f,1f, 0f,1f,-1f, 0f,-1f,-1f)
		for i in range( data.Length ):
			data[i] = 0.5f * (data[i]+1f)
		GL.TexImage1D( targ, 0, PixelInternalFormat.Rgb8, 12, 0,
			PixelFormat.Rgb, PixelType.Float, data )
	
	public def generate(order as byte) as void:
		# allocate storage
		rnd = System.Random()
		data = array[of ushort]( 1<<order )
		shift = 16 - order	# for ushort
		# Sattolo's algorithm
		for i in range( data.Length ):
			data[i] = i<<shift
		i = data.Length
		while --i>0:
			j = rnd.Next() % i
			x = data[i]
			data[i] = data[j]
			data[j] = x
		# check cycle length
		i,j = data[0],1
		while i != 0:
			i = data[i>>shift]
			++j
		assert j == data.Length
		# upload
		tPerm.Value.bind()
		pif = (PixelInternalFormat.R8, PixelInternalFormat.R16)[ order>8 ]
		GL.TexImage1D( targ, 0, pif, data.Length, 0,
			PixelFormat.Red, PixelType.UnsignedShort, data )
