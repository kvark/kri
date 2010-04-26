namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL

private class RenderPoints( kri.rend.Basic ):
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


private class BehSimple( kri.part.beh.Basic ):
	public final tVert	= kri.shade.par.Value[of kri.Texture]('vertex')
	public final tQuat	= kri.shade.par.Value[of kri.Texture]('quat')
	public final parPlane	= kri.shade.par.Value[of Vector4]('coord_plane')
	public final parSphere	= kri.shade.par.Value[of Vector4]('coord_sphere')
	public final parCoef	= kri.shade.par.Value[of single]('reflect_koef')
	
	public def constructor(pc as kri.part.Context):
		super('./text/beh_simple')
		enrich(2, pc.at_sys)
		enrich(4, pc.at_pos)
		enrich(4, pc.at_speed)
	
	public override def link(d as kri.shade.rep.Dict) as void:
		d.unit(tVert,tQuat)
		d.var(parPlane,parSphere)
		d.var(parCoef)
		

private def createParticle(ent as kri.Entity) as kri.part.Emitter:
	pm = kri.part.Manager(100)
	pe = kri.part.Emitter(pm,'test')
	pcon = kri.part.Context()
	#todo: just use a proper root shader
	pm.makeStandard(pcon)
	pm.col_update.extra.Add( kri.shade.Object('/part/born/instant_v') )
	beh = BehSimple(pcon)
	beh.parPlane.Value	= Vector4(1f,0f,0f,1f)
	beh.parSphere.Value	= Vector4( ent.node.local.pos, 3f )
	beh.parCoef.Value = 0.9f
	pm.behos.Add( beh )
	pm.behos.Add( kri.part.beh.Basic('/part/beh/bounce_plane') )
	pm.behos.Add( kri.part.beh.Basic('/part/beh/bounce_sphere') )
	
	if 'face':
		pe.onUpdate = def(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
			tag = e.seTag[of kri.kit.bake.Tag]()
			if tag:
				beh.tVert.Value = tag.tVert
				beh.tQuat.Value = tag.tQuat
	else: #vertex
		a = kri.Ant.Inst.attribs
		beh.tVert.Value = kri.Texture( TextureTarget.TextureBuffer )
		beh.tVert.Value.bind()
		kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.find(a.vertex) )
		beh.tQuat.Value = kri.Texture( TextureTarget.TextureBuffer )
		beh.tQuat.Value.bind()
		kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.find(a.quat) )
		pe.onUpdate = def(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
			return true
	
	pm.init(pcon)
	pe.allocate()
	pe.obj = ent
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
		ent.node.local.rot = Quaternion.FromAxisAngle(Vector3.UnitX,1f)
		view.scene.entities.Add(ent)
		
		m2 = kri.kit.gen.sphere(2, 2f*Vector3.One)
		e2 = kri.kit.gen.entity( m2, con )
		e2.node = ent.node
		view.scene.entities.Add(e2)
		
		tag = kri.kit.bake.Tag(256,256, 16,8, true)
		ent.tags.Add(tag)
		#proxy = kri.shade.par.UnitProxy({ return tag.tVert })
		#proxy = kri.shade.par.UnitProxy({ return view.con.Depth })
		#proxy = kri.shade.par.UnitProxy({ return view.scene.lights[0].depth })
		
		ps = createParticle(ent)
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.kit.bake.Update() )
		rlis.Add( kri.rend.Emission( fillDepth:true ) )
		#assert not 'ready'
		#rlis.Add( kri.rend.part.Simple(true,false) )
		rlis.Add( RenderPoints() )
		if 'Light':
			licon = kri.rend.light.Context(2,8)
			#licon.setExpo(120f, 0.5f)
			rlis.Add( kri.rend.light.Fill(licon) )
			rlis.Add( kri.rend.light.Apply(licon) )
			#rlis.Add( kri.rend.debug.Map(true,proxy) )
			#rlis.Add( kri.rend.FilterCopy() )
		
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.ControlMouse(ent.node,0.002f) )
		if 'Part Anims':
			al.add( kri.ani.Particle(ps) )
		ant.Keyboard.KeyDown += { ps.owner.tick(ps) }
		ant.Run(30.0,30.0)
