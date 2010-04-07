namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL

private class RenderPoints(kri.rend.Basic):
	final sa	= kri.shade.Smart()
	final vbo	= kri.vb.Attrib()
	final va	= kri.vb.Array()
	final node	= kri.Node('x')
	public def constructor():
		super(false)
		sp = node.Local
		sp.pos.Z = -10f
		node.Local = sp
		
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


private def createParticle(em as kri.Entity) as kri.part.Emitter:
	pm = kri.part.Manager(400)
	pcon = kri.part.Context()
	pcon.sh_born = kri.shade.Object('/part/born_instant_v')
	beh = kri.part.Behavior('/part/beh_simple')
	sl = kri.Ant.Inst.slotParticles
	at_pos		= sl.getForced('pos')
	at_speed	= sl.getForced('speed')
	beh.semantics.Add( kri.vb.attr.Info(
		slot:at_pos,	size:3, type:VertexAttribPointerType.Float ))
	beh.semantics.Add( kri.vb.attr.Info(
		slot:at_speed,	size:3, type:VertexAttribPointerType.Float ))
	pm.behos.Add(beh)
	pm.init(pcon)
	
	pe = kri.part.Emitter(pm,em)
	pe.sa.add( pcon.sh_draw )
	pe.sa.add( '/part/draw_simple_v', '/part/draw_simple_f', 'quat', 'tool')
	pe.sa.link( sl, kri.Ant.Inst.dict )	
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
		
		mesh = kri.kit.gen.cube( Vector3.One )
		con = kri.load.Context()
		ent = kri.kit.gen.entity( mesh, con )
		ent.node = kri.Node('main')
		sp = kri.Spatial.Identity
		sp.pos.Z = -30f
		ent.node.Local = sp
		view.scene.entities.Add(ent)
		
		ps = createParticle(ent)
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.kit.skin.Update() )
		rlis.Add( kri.rend.Emission( fillDepth:true ) )
		rlis.Add( kri.rend.Particles() )
		rlis.Add( RenderPoints() )
		if 'Light':
			licon = kri.rend.light.Context(2,6)
			licon.setExpo(120f, 0.5f)
			rlis.Add( kri.rend.light.Fill(licon) )
			rlis.Add( kri.rend.light.Apply(licon) )
		
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.ControlMouse(ent.node,0.002f) )
		if 'Part Anims':
			part = kri.ani.Particle(ps)
			part.lTime = 10000.0
			al.add(part)
		ant.Keyboard.KeyDown += { ps.man.tick(ps) }
		ant.Run(30.0,30.0)
