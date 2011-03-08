namespace support.hdr

import System

public class Context:
	public avg	as single	= 1f
	

public class Render( kri.rend.Basic ):
	private final buf	= kri.buf.Target()
	private final b2	= kri.buf.Target()
	private final pbo	= kri.vb.Pack()
	private final context	as Context
	private final sa_bright	= kri.shade.Smart()
	private final sa_scale	= kri.shade.Smart()
	private final sa_tone	= kri.shade.Smart()
	private final tInput	= kri.shade.par.Texture('input')
	private final pExpo		= kri.shade.par.Value[of single]('exposure')
	
	public def constructor(ctx as Context):
		super(true)
		context = ctx
		sl = kri.Ant.Inst.slotAttributes
		pExpo.Value = 1f
		d = kri.shade.rep.Dict()
		d.unit(tInput)
		d.var(pExpo)
		sa_bright	.add('/copy_v','/hdr/bright_f')
		sa_bright	.link(sl, d, kri.Ant.Inst.dict)
		sa_scale	.add('/copy_v','/copy_f')
		sa_scale	.link(sl, d, kri.Ant.Inst.dict)
		sa_tone		.add('/copy_v','/hdr/tone_f')
		sa_tone		.link(sl, d, kri.Ant.Inst.dict)
	
	public virtual def setup(pl as kri.buf.Plane) as bool:
		buf.resize( pl.wid, pl.het )
		pbo.init( sizeof(single) )
		return true
	
	public virtual def process(con as kri.rend.Context) as void:
		# update context
		data = (of single:-1f,)
		pbo.read(data)
		context.avg = data[0]
		# init texture
		assert not con.Input
		con.DepthTest = false
		#pl = buf.getInfo()
		#w = pl.wid
		#h = pl.het
		tInput.Value = t = con.Input
		buf.at.color[0] = b2.at.color[0] = t
		scale = t.genLevels()	# to be sure
		t.filt(true,false)
		scale = 8
		# bright filter
		t.level = 1
		t.setLevels(0,0)
		sa_bright.use()
		buf.mask = b2.mask = 1
		b2.bind()
		kri.Ant.Inst.quad.draw()
		# down-sample
		# TODO: support!
		/*
		for i in range(1,scale):
			buf.init(w,h,i)
			t.setLevels(i,i)
			b2.init(w,h,i+1)
			b2.A[0].Level = i+1
			buf.blit(b2)
		# read back
		pbo.bind()
		assert b2.Width==1 and b2.Height==1
		b2.read(PixelFormat.Alpha, PixelType.Float)
		# blend up
		sa_scale.use()
		using blend = kri.Blender():
			blend.Alpha = 0.1f
			blend.skipAlpha()
			for i in range(scale,0,-1):
				buf.init(w,h,i-1)
				buf.A[0].Level = i-1
				buf.activate()
				t.setLevels(i,i)
				kri.Ant.Inst.quad.draw()
		*/
		# tone filter
		t.level = 0
		t.setLevels(0,10)
		t.filt(false,false)
		sa_tone.use()
		con.activate()
		kri.Ant.Inst.quad.draw()
