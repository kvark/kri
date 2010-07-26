namespace kri.kit.hdr

import System
import OpenTK.Graphics.OpenGL

public class Context:
	public avg	as single	= 1f
	

public class Render( kri.rend.Basic ):
	private final buf	= kri.frame.Buffer(0, TextureTarget.TextureRectangle )
	private final sa_bright	= kri.shade.Smart()
	private final sa_scale	= kri.shade.Smart()
	private final sa_tone	= kri.shade.Smart()
	public	final reduct	as uint
	public	final scale		= 8
	
	public def constructor(red as uint):
		super(true)
		reduct = red
		sl = kri.Ant.Inst.slotAttributes
		sa_bright	.add('/hdr/bright_f')
		sa_bright	.link(sl, kri.Ant.Inst.dict)
		sa_scale	.add('/hdr/scale_f')
		sa_scale	.link(sl, kri.Ant.Inst.dict)
		sa_tone		.add('/hdr/tone_f')
		sa_tone		.link(sl, kri.Ant.Inst.dict)
		buf.emitAuto(0,16)
	
	public virtual def setup(far as kri.frame.Array) as bool:
		buf.init(far.Width>>reduct, far.Height>>reduct)
		buf.resizeFrames(0)
		return true
	
	public virtual def process(con as kri.rend.Context) as void:
		con.DepTest = false
		# bright filter
		assert 'not ready'
		# u.Tex[ u.input ] = con.Input
		buf.mask = 1
		buf.activate()
		sa_bright.use()
		kri.Ant.Inst.emitQuad()
		# gen levels
		kri.Texture.GenLevels()
		# read a pixel
		using blend = kri.Blender():
			blend.Alpha = 0.1f
			blend.skipAlpha()
			for i in range(scale):
				#set base level = scale-i
				#set target = base level-1
				sa_scale.use()
				kri.Ant.Inst.emitQuad()
			blend.add()
			# tone filter
			#set input level 0
			buf.A[1].Tex = con.Input
			buf.mask = 2
			buf.activate()
			sa_tone.use()
			kri.Ant.Inst.emitQuad()
			buf.A[1].Tex = null
