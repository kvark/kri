namespace support.defer

import OpenTK.Graphics.OpenGL
import kri.shade

#---------	CONTEXT	--------#

public class Context:
	public final buf		= kri.buf.Holder( mask:7 )
	public final dict		= par.Dict()
	public final texDepth	= par.Texture('depth')
	public final useNormals	= par.Value[of bool]('use_normals')
	public final sh_diff	= Object.Load('/mod/lambert_f')
	public final sh_spec	= Object.Load('/mod/phong_f')
	public final sh_apply	= Object.Load('/g/apply_f')
	
	public def constructor():
		dict.unit(texDepth)
		dict.var(useNormals)
		useNormals.Value = false
		# diffuse, specular, world space normal
		for i in range(3):
			pt = par.Texture('g'+i)
			tex = kri.buf.Texture(0, PixelInternalFormat.Rgb10A2, PixelFormat.Rgba )
			buf.at.color[i] = pt.Value = tex
			#pt.Value.filt(false,false)	# not valid with MS
			dict.unit(pt)


#---------	GROUP	--------#

public class Group( kri.rend.Group ):
	public	final con	as Context
	public def constructor(qord as byte, lc as support.light.Context, pc as kri.part.Context):
		cx = Context()
		rl = List[of kri.rend.Basic]()
		rl.Add( fill.Quat(cx) )
		#rl.Add( fill.Norm(cx) )
		if lc:	rl.Add( Apply	(lc,cx,qord) )
		if pc:	rl.Add( Particle(pc,cx,qord) )
		super( *rl.ToArray() )
		con = cx

