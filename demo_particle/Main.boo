namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL

private class RenderPoints(kri.rend.Basic):
	final sa	= kri.shade.Smart()
	final vbo	= kri.vb.Attrib()
	final va	= kri.vb.Array()
	final node	= kri.Node('x')
	final tf	= kri.TransFeedback(1)
	public def constructor():
		super(false)
		node.local.pos.Z = -10f
		
		sa.add('./text/point_v', './text/point_f', 'tool', 'quat', 'fixed')
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		va.bind()
		vbo.init[of Vector2h]((
			Vector2h(-1f,-1f),
			Vector2h(1f,-1f),
			Vector2h(1f,1f),
			Vector2h(-1f,1f)
			), false)
		ai = kri.vb.attr.Info( slot:kri.Ant.Inst.attribs.vertex,
			integer:false, size:2, type:VertexAttribPointerType.HalfFloat )
		vbo.semantics.Add(ai)
		vbo.attribFirst()
		
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		kri.Ant.Inst.params.modelView.activate(node)
		GL.PointSize(50.0)
		va.bind()
		using blend = kri.Blender():
			blend.add()
			sa.use()
			GL.DrawArrays( BeginMode.Points, 0, 4 )


private def createParticle(ent as kri.Entity) as kri.part.Emitter:
	pm = kri.part.Manager(100)
	pm.sh_born = kri.shade.Object('/part/born/instant_v')
	beh = kri.part.Behavior('./text/beh_simple')
	sl = kri.Ant.Inst.slotParticles
	at_pos		= sl.getForced('pos')
	at_speed	= sl.getForced('speed')
	beh.semantics.Add( kri.vb.attr.Info(
		slot:at_pos,	size:3, type:VertexAttribPointerType.Float ))
	beh.semantics.Add( kri.vb.attr.Info(
		slot:at_speed,	size:3, type:VertexAttribPointerType.Float ))
	pm.behos.Add(beh)
	
	tVert = kri.shade.par.Texture(0,'vertex')
	tQuat = kri.shade.par.Texture(1,'quat')
	pm.dict.unit(tVert)
	pm.dict.unit(tQuat)
	if 'face':
		pm.onUpdate = def(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
			tag = e.seTag[of kri.kit.bake.Tag]()
			if tag:
				tVert.Value = tag.tVert
				tQuat.Value = tag.tQuat
	else: #vertex
		a = kri.Ant.Inst.attribs
		tVert.Value = kri.Texture( TextureTarget.TextureBuffer )
		tVert.Value.bind()
		kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.find(a.vertex) )
		tQuat.Value = kri.Texture( TextureTarget.TextureBuffer )
		tQuat.Value.bind()
		kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.find(a.quat) )
		pm.onUpdate = def(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
	
	pcon = kri.part.Context()
	pm.init(pcon)
	pe = kri.part.Emitter(pm,'test')
	pe.sa = kri.shade.Smart()
	pe.sa.add( pcon.sh_draw )
	pe.sa.add( './text/draw_simple_v', './text/draw_simple_f', 'quat', 'tool')
	pe.sa.link( sl, kri.Ant.Inst.dict )	
	pe.obj = ent
	pe.init()
	return pe


[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant(1,400,300,24):
		view = kri.ViewScreen(16,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.scene.lights.Add( kri.Light() )
		
		#mesh = kri.kit.gen.cube( Vector3.One )
		mesh = kri.kit.gen.plane_tex( Vector2.One )
		con = kri.load.Context()
		ent = kri.kit.gen.entity( mesh, con )
		ent.node = kri.Node('main')
		ent.node.local.pos.Z = -30f
		view.scene.entities.Add(ent)
		
		tag = kri.kit.bake.Tag(256,256, 16,8, true)
		ent.tags.Add(tag)
		tval = kri.shade.par.Value[of kri.Texture]()
		tval.Value = tag.tVert
		
		ps = createParticle(ent)
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.kit.bake.Update() )
		rlis.Add( kri.rend.Emission( fillDepth:true ) )
		rlis.Add( kri.rend.Particles(true,false) )
		rlis.Add( RenderPoints() )
		if 'Light':
			licon = kri.rend.light.Context(2,6)
			licon.setExpo(120f, 0.5f)
			rlis.Add( kri.rend.light.Fill(licon) )
			rlis.Add( kri.rend.light.Apply(licon) )
			#rlis.Add( kri.rend.debug.Map(tval) )
		
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.ControlMouse(ent.node,0.002f) )
		if 'Part Anims':
			part = kri.ani.Particle(ps)
			part.lTime = 10000.0
			al.add(part)
		ant.Keyboard.KeyDown += { ps.man.tick(ps) }
		ant.Run(30.0,30.0)
