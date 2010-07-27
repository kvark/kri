namespace demo

import System
import Jitter
import OpenTK


public class Anim( kri.ani.Delta ):
	public final world	as World
	public final view	as kri.View
	public final lcon	as kri.load.Context
	private final mouse = kri.Ant.Inst.Mouse
	#private final shape = Collision.Shapes.SphereShape(1f)
	private final shape = Collision.Shapes.BoxShape(2f,2f,2f)
	private num	= 0
	
	public def sync(body as Dynamics.RigidBody, node as kri.Node) as void:
		pos = body.Position
		node.local.pos = Vector3( pos.X, pos.Y, pos.Z )
		quat = LinearMath.JQuaternion.CreateFromMatrix( body.Orientation )
		node.local.rot = Quaternion( quat.X, quat.Y, quat.Z, quat.W )
		node.touch()
	
	public def sync(node as kri.Node, body as Dynamics.RigidBody) as void:
		ws = node.World
		p = ws.pos
		body.Position = LinearMath.JVector( p.X, p.Y, p.Z )
		q = ws.rot
		qj = LinearMath.JQuaternion( q.X, q.Y, q.Z, q.W )
		body.Orientation = LinearMath.JMatrix.CreateFromQuaternion(qj)
	
	public def genBall() as void:
		# object
		#mesh = kri.kit.gen.Sphere( 2, Vector3.One )
		mesh = kri.kit.gen.Cube( Vector3.One )
		ent = kri.kit.gen.Entity( mesh, lcon )
		view.scene.entities.Add(ent)
		ent.node = kri.Node( 'gen-' + ++num )
		# pos from NDC
		ptr = kri.Ant.Inst.PointerNdc
		ptr.Z = -5f
		if view.cam.node:
			ent.node.local.pos = view.cam.node.World.byPoint(ptr)
		else: ent.node.local.pos = ptr
		# body
		body = Dynamics.RigidBody(shape)
		body.LinearVelocity = LinearMath.JVector( 10f*ptr.X, 10f*ptr.Y, -20f )
		body.Tag = ent.node
		world.AddBody(body)
		sync( ent.node, body )

	public def constructor(w as World, v as kri.View, ln as kri.load.Context):
		mouse.ButtonDown += genBall
		world = w
		view = v
		lcon = ln
		for rb in world.RigidBodies:
			n = rb.Tag as kri.Node
			assert n and not n.Parent
			sync(n,rb)
	
	protected override def onDelta(delta as double) as uint:
		world.Step(delta,false)
		toRemove = List[of Dynamics.RigidBody]()
		
		for rb in world.RigidBodies:
			n = rb.Tag as kri.Node
			assert n
			if rb.Position.LengthSquared() > 1000f:
				toRemove.Add(rb)
				view.scene.entities.RemoveAll() do(e as kri.Entity):
					return e.node == n
			else: sync(rb,n)

		for rb in toRemove:
			world.RemoveBody(rb)
		return 0



[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',24):
		view = kri.ViewScreen(0,8,0)
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera( rangeIn:1f, rangeOut:50f )
		view.scene.lights.Add( lit = kri.Light() )
		lit.fov = 0f
		
		loadCon = kri.load.Context()
		cosys = Collision.CollisionSystemSAP()
		world = World(cosys)
		mesh as kri.Mesh = null
		ent as kri.Entity = null
		shape as Collision.Shapes.Shape = null
		
		# object
		mesh = kri.kit.gen.Sphere( 2, Vector3.One )
		ent = kri.kit.gen.Entity( mesh, loadCon )
		view.scene.entities.Add(ent)
		ent.node = kri.Node('sphere')
		ent.node.local.pos.Z = -20f
		# body
		shape = Collision.Shapes.SphereShape(1f)
		body = Dynamics.RigidBody(shape)
		body.Tag = ent.node
		world.AddBody(body)
		
		# plane
		radius = 10f
		mesh = kri.kit.gen.Plane( Vector2(radius,radius) )
		ent = kri.kit.gen.Entity( mesh, loadCon )
		view.scene.entities.Add(ent)
		ent.node = kri.Node('plane')
		ent.node.local.rot = Quaternion.FromAxisAngle( Vector3.UnitX, -1.2f )
		ent.node.local.pos = Vector3(0f, -2f, -20f)
		# body
		r2 = 2f*radius - 1f
		shape = Collision.Shapes.BoxShape( LinearMath.JVector(r2,r2,1f) )
		body = Dynamics.RigidBody(shape)
		body.IsStatic = true
		body.Tag = ent.node
		world.AddBody(body)
		
		view.ren = rc = kri.rend.Chain()
		rem = kri.rend.Emission( fillDepth:true )
		rem.backColor = Graphics.Color4(0f,0.3f,0.5f,1)
		#rem.pBase.Value = Graphics.Color4(1,0,0,1)
		#licon = kri.rend.light.Context(2,8)
		rc.renders.Add( rem )
		rc.renders.Add( kri.rend.light.omni.Apply(false) )
		
		ant.anim = al = kri.ani.Scheduler()
		al.add( Anim( world, view, loadCon ))
		ant.Run(30.0,30.0)
