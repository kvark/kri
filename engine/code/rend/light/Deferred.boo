namespace kri.rend.light.g

import System
import OpenTK.Graphics.OpenGL
import kri.rend


#---------	RENDER TO G-BUFFER	--------#

public class Fill( tech.Meta ):
	public final buf		= kri.frame.Buffer()
	public GBuf as kri.Texture:
		get: return buf.A[0].Tex
	# init
	public def constructor():
		super('g.make', kri.load.Meta.LightSet,
			('/g/make_v','/g/make_f','/light/common_f'))
		t = kri.Texture( TextureTarget.Texture2DArray )
		buf.A[0].layer(t,0)	# diffuse color * texture
		buf.A[1].layer(t,1)	# specular color
		buf.A[2].layer(t,2)	# world space normal
		buf.mask = 0x7
	# resize
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.getW, far.getH )
		buf.A[0].Tex.bind()
		fm = kri.Texture.AskFormat( kri.Texture.Class.Color, 8 )
		fm = PixelInternalFormat.Rgb10A2
		kri.Texture.InitArray(fm, far.getW, far.getH, 3)
		kri.Texture.Filter(false,false)
		return true
	# work	
	public override def process(con as Context) as void:
		con.needDepth(false)
		buf.A[-1].Tex = con.Depth
		buf.activate()
		con.SetDepth(0f, false)
		con.ClearColor()
		drawScene()


#---------	RENDER APPLY G-BUFFER	--------#

public class Apply( Basic ):
	public final gid	= kri.lib.Const.offUnit
	protected final s0	= kri.shade.Smart()
	protected final sa	= kri.shade.Smart()
	private final gbuf		= kri.shade.par.Texture(0, 'gbuf')
	private final texLit	= kri.shade.par.Texture(1, 'light')
	private final texDep	= kri.shade.par.Texture(2, 'depth')
	private final context	as light.Context
	private final pArea	= kri.shade.par.Value[of OpenTK.Vector4]()
	# init
	public def constructor(gt as kri.Texture, lc as light.Context):
		super(false)
		context = lc
		gbuf.Value = gt
		# fill shader
		s0.add( 'copy_v', '/g/init_f' )
		s0.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		# light shader
		d = kri.shade.rep.Dict()
		d.add('area', pArea)
		d.unit(gbuf,texLit,texDep)
		pArea.Value = OpenTK.Vector4( 0f,0f,0f,1f )
		sa.add( '/g/apply_v', '/g/apply_f' )
		sa.add( '/mod/lambert_f', '/mod/phong_f' )
		sa.link( kri.Ant.Inst.slotAttributes, d, lc.dict, kri.Ant.Inst.dict )
	# calculate
	private def setArea(l as kri.Light) as void:
		c = kri.Camera.Current
		scam = c.node.World
		sp = slit = l.node.World
		scam.inverse()
		sp.combine( slit, scam )
		p0 = c.project( sp.pos )
		p2 = sp.pos + OpenTK.Vector3(1f,1f,0f) * (l.rangeOut * sp.scale)
		p1 = c.project(p2) - p0
		pArea.Value = OpenTK.Vector4( p0.X, p0.Y, p1.X, p1.Y )
	# shadow 
	private def bindShadow(t as kri.Texture) as void:
		if t:
			texLit.Value = t
			t.bind()
			kri.Texture.Filter(false,false)
			kri.Texture.Shadow(false)
		else: context.defShadow.bind()
	# work
	public override def process(con as Context) as void:
		con.activate()
		assert 'not ready'
		texDep.bindSlot( con.Depth )
		kri.Texture.Filter(false,false)
		kri.Texture.Shadow(false)
		# initial fill
		s0.use()
		kri.Ant.Inst.emitQuad()
		# add lights
		using blend = kri.Blender():
			blend.add()
			for l in kri.Scene.current.lights:
				setArea(l)
				kri.Texture.Slot( texLit.tun )
				bindShadow( l.depth )
				kri.Ant.Inst.params.activate(l)
				sa.use()
				kri.Ant.Inst.emitQuad()
