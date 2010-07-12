namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL


private class BehSimple( kri.part.beh.Basic ):
	public final tVert	= kri.shade.par.Value[of kri.Texture]('vertex')
	public final tQuat	= kri.shade.par.Value[of kri.Texture]('/lib/quat_v')
	public final parPlane	= kri.shade.par.Value[of Vector4]('coord_plane')
	public final parSphere	= kri.shade.par.Value[of Vector4]('coord_sphere')
	public final parCoef	= kri.shade.par.Value[of single]('reflect_koef')
	
	public def constructor(pc as kri.part.Context):
		super('text/beh_simple')
		kri.Help.enrich( self, 2, pc.at_sys )
		kri.Help.enrich( self, 4, pc.at_pos, pc.at_speed)
	
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
	pm.col_update.extra.Add( kri.shade.Object.Load('/part/born/instant_v') )
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


private def genMap() as (single,2):
	radius = 20
	size = radius+radius+1
	hm = matrix(single,size,size)
	vc = Vector2(radius,radius)
	het = 0.01f
	hsin = 1f
	
	for i in range(size):
		for j in range(size):
			vij = Vector2(i,j) - vc
			dist = vij.LengthFast
			angle = Math.PI * Math.Min(1.5f, 2.2f*dist / radius - 0.5f)
			kbase = het*(radius-dist)
			kadd = hsin*( 1.0 + Math.Sin(angle) )
			hm[i,j] = cast(single, kbase + kadd)
	return hm



[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen(0,16,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.scene.lights.Add( kri.Light() )
		
		#mesh = kri.kit.gen.cube( Vector3.One )
		mesh = kri.kit.gen.Landscape( genMap(), Vector3(1f,1f,5f) )
		con = kri.load.Context()
		ent = kri.kit.gen.Entity( mesh, con )
		ent.node = kri.Node('main')
		ent.node.local.pos.Z = -75f
		ent.node.local.rot = Quaternion.FromAxisAngle(Vector3.UnitX,-1f)
		view.scene.entities.Add(ent)
		
		#tag = kri.kit.bake.Tag(256,256, 16,8, true)
		#ent.tags.Add(tag)
		#proxy = kri.shade.par.UnitProxy({ return tag.tVert })
		#proxy = kri.shade.par.UnitProxy({ return view.con.Depth })
		#proxy = kri.shade.par.UnitProxy({ return view.scene.lights[0].depth })
		
		#ps = createParticle(ent)
		#view.scene.particles.Add(ps)
		
		#rlis.Add( kri.kit.bake.Update() )
		#rlis.Add( kri.rend.debug.MapDepth() )
		rem = kri.rend.Emission( fillDepth:true )
		rlis.Add( rem )
		rem.pBase.Value = Graphics.Color4.Black
		
		#assert not 'ready'
		#rlis.Add( kri.rend.part.Simple(true,false) )
		if 'Light':
			licon = kri.rend.light.Context(2,8)
			#licon.setExpo(120f, 0.5f)
			rlis.Add( kri.rend.light.Fill(licon) )
			rlis.Add( kri.rend.light.Apply(licon) )
			rlis.Add( kri.rend.FilterCopy() )
		
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.ControlMouse(ent.node,0.003f) )
		#if 'Part Anims':
			#al.add( kri.ani.Particle(ps) )
		#ant.Keyboard.KeyDown += { ps.owner.tick(ps) }
		ant.Run(30.0,30.0)
