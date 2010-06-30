namespace demo

import System
import System.Collections.Generic
import OpenTK

public class AniTrans( kri.ani.Loop ):
	private final n	as kri.Node
	private s0	as kri.Spatial
	private s1	as kri.Spatial
	public def constructor(node as kri.Node, ref targ as kri.Spatial):
		n = node
		s0 = n.local
		s1 = targ
		lTime = 0.5
	protected override def onRate(rate as double) as void:
		n.local.lerpDq(s0,s1,rate)
		n.touch()


public class AniRot( kri.ani.Loop ):
	private static final time = 0.5
	private final n as kri.Node
	private final s0 as kri.Spatial
	private final pos	as Vector3
	private final axis	as Vector3

	public def constructor(node as kri.Node, ref targ as kri.Spatial):
		n = node
		s0 = n.local
		pos = 0.5 * ( targ.pos + s0.pos )
		diff = targ.pos - s0.pos
		diff.Normalize()
		axis = Vector3.Cross(diff, Vector3.UnitZ )
		lTime = time
	protected override def onRate(rate as double) as void:
		s3 = s0
		s3.pos -= pos
		s2 = kri.Spatial.Identity
		s2.rot = Quaternion.FromAxisAngle( axis, rate*Math.PI )
		n.local.combine(s3,s2)
		n.local.pos += pos
		n.touch()



private class Task:
	private static final size	= 5
	private ec	as kri.Entity	= null
	private final al	as kri.ani.Scheduler = null

	public def fun(e as kri.Entity, point as Vector3) as void:
		if not 'Swap':
			kri.Help.swap[of kri.Spatial]( e.node.local, ec.node.local )
			e.node.touch()
			ec = e
		diff = Vector3.Subtract( ec.node.local.pos, e.node.local.pos )
		ax,ay = Math.Abs(diff.X), Math.Abs(diff.Y)
		return	if not al.Empty or ax+ay>7f
		al.add( AniRot(e.node,ec.node.local) )
		#al.add( AniTrans(e.node,ec.node.local) )
		ec.node.local = e.node.local
		ec.node.touch()
		#al.add( e.node.play('rotate') )
	
	private def makeMat() as kri.Material:
		con = kri.load.Context()
		mat = kri.Material( con.mDef )
		mat.link()
		return mat
	
	private def makeEnt() as kri.Entity:
		mat = makeMat()
		# create mesh
		m = kri.kit.gen.Cube( Vector3(2f,1f,0.5f) )
		e = kri.Entity( mesh:m )
		e.tags.Add( kri.TagMat( mat:mat, num:m.nPoly ) )
		e.tags.Add( kri.kit.pick.Tag( pick:fun ) )
		return e
	
	private def makeRec() as kri.ani.data.Record:
		def fani(pl as kri.ani.data.IPlayer, val as Vector3, id as byte):
			n = pl as kri.Node
			n.local.pos = val
			n.touch()
		rec = kri.ani.data.Record('rotate',3f)
		ch = kri.ani.data.Channel_Vector3(4,0,fani)
		ch.lerp = Vector3.Lerp
		ch.bezier = false
		var = (Vector3.Zero, Vector3.UnitX, -Vector3.UnitX, Vector3.Zero)
		tar = (0f, 1f, 2f, 3f)
		for i in range( ch.kar.Length ):
			ch.kar[i] = kri.ani.data.Key[of Vector3]( t:tar[i], co:var[i] )
		rec.channels.Add(ch)
		return rec

	public def constructor(ar as List[of kri.Entity], sched as kri.ani.Scheduler):
		al = sched
		e = makeEnt()
		rec = makeRec()
		# populate
		for i in range(size*size):
			ec = kri.Entity(e)
			ec.node = n = kri.Node('cell')
			n.anims.Add(rec)
			if e.node:
				n.Parent = e.node.Parent
				n.local = e.node.local
			x,y = (i % size),(i / size)
			n.local.pos = Vector3( (x+x+1-size)*3f, (y+y+1-size)*2f, -40f )
			ar.Add(ec)
		(ec = ar[0]).visible = false
		ec.tags.RemoveAll() do(t as kri.ITag):
			t2 = t as kri.kit.pick.Tag
			return t2 != null



[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',24):
		view = kri.ViewScreen(8,0)
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera( rangeIn:30f, rangeOut:50f )
		view.scene.lights.Add( kri.Light() )
	
		rem = kri.rend.Emission( fillDepth:true )
		rem.backColor = Graphics.Color4(0f,0.3f,0.5f,1)
		#rem.pBase.Value = Graphics.Color4(1,0,0,1)
		licon = kri.rend.light.Context(2,8)
		
		view.ren = rm = kri.rend.Manager(false)
		rm.add('skin',	1,	kri.kit.skin.Update(true) )
		rm.add('emi',	3,	rem, 'skin')
		rm.add('pick',	3,	kri.kit.pick.Render(2,8), 'emi')
		rm.add('fill',	2,	kri.rend.light.Fill(licon) )
		rm.add('app',	4,	kri.rend.light.Apply(licon), 'emi','fill')
		
		ant.anim = al = kri.ani.Scheduler()
		Task( view.scene.entities, al )
		#e = at.scene.entities[0]
		#skel = e.seTag[of kri.kit.skin.Tag]().skel
		#skel.moment(3f, skel.find('Action'))
		#al.add( kri.kit.skin.Anim(e,'Action') )
		ant.Run(30.0,30.0)
