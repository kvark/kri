namespace support.defer

import OpenTK.Graphics.OpenGL
import kri.shade

#---------	CONTEXT	--------#

public class Context:
	public final buf		= kri.buf.Holder( mask:7 )
	public final dict		= par.Dict()
	public final texDepth	= par.Texture('depth')
	public final sh_diff	= Object.Load('/mod/lambert_f')
	public final sh_spec	= Object.Load('/mod/phong_f')
	public final sh_apply	= Object.Load('/g/apply_f')
	
	public def constructor():
		dict.unit(texDepth)
		# diffuse, specular, world space normal
		for i in range(3):
			pt = par.Texture('g'+i)
			tex = kri.buf.Texture(0, PixelInternalFormat.Rgba8, PixelFormat.Rgba )
			buf.at.color[i] = pt.Value = tex
			#pt.Value.filt(false,false)	# not valid with MS
			dict.unit(pt)


#---------	GROUP	--------#

public class Group( kri.rend.Group ):
	public	final	con		as Context
	public	final	rFill		as fill.Fork	= null
	public	final	rLayer		as layer.Fill	= null
	public	final	rApply		as Apply		= null
	public	final	rParticle	as Particle		= null
	public	Layered	as bool:
		get: return rLayer.active
		set:
			rLayer.active = value
			rFill.active = not value
	
	public def constructor(qord as byte, lc as support.light.Context, pc as kri.part.Context):
		con = cx = Context()
		rFill	= fill.Fork(cx)
		rLayer	= layer.Fill(cx)
		rl = List[of kri.rend.Basic]()
		rl.Extend(( rFill, rLayer ))
		if lc:
			rApply = Apply(lc,cx,qord)
			rl.Add(rApply)
		if pc:
			rParticle = Particle(pc,cx,qord)
			rl.Add(rParticle)
		super( *rl.ToArray() )
