namespace demo.pick

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
	private static final time = 0.3
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
		if not al.Empty or ax+ay>8f:
			return
		al.add( AniRot(e.node,ec.node.local) )
		#al.add( AniTrans(e.node,ec.node.local) )
		ec.node.local = e.node.local
		ec.node.touch()
		#al.add( e.node.play('rotate') )
	
	private def makeMat(texName as string) as kri.Material:
		con = kri.load.Context()
		mat = kri.Material( con.mDef )
		if texName:
			targa = kri.load.image.Targa()
			tex = targa.read(texName).generate()
			con.setMatTexture(mat,tex)
		mat.link()
		return mat
	
	private def makeEnt(texName as string) as kri.Entity:
		mat = makeMat(texName)
		# create mesh
		m = kri.gen.Cube( Vector3(3f,2f,0.5f) )
		e = kri.Entity( mesh:m )
		e.tags.Add( kri.TagMat( mat:mat, num:m.nPoly ))
		e.tags.Add( support.pick.Tag( pick:fun ))
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
		tar = (0f, 1f, 2f, 3f)
		var = (Vector3.Zero, Vector3.UnitX, -Vector3.UnitX, Vector3.Zero)
		for i in range( ch.kar.Length ):
			ch.kar[i] = kri.ani.data.Key[of Vector3]( t:tar[i], co:var[i] )
		rec.channels.Add(ch)
		return rec
	
	private def makeTexCoord(x as uint, y as uint) as kri.vb.Attrib:
		vbo = kri.vb.Attrib()
		kri.Help.enrich(vbo,2,'tex0')
		data = array[of Vector2](8)
		for k in range(data.Length):
			x1 = x+(((k+0)>>1)&1)
			y1 = y+(((k+1)>>1)&1)
			data[k] = Vector2( x1*1f / size, y1*1f / size )
		vbo.init(data,false)
		return vbo

	public def constructor(ar as List[of kri.Entity], sched as kri.ani.Scheduler, texName as string):
		al = sched
		e = makeEnt(texName)
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
			n.local.pos = Vector3( (x+x+1-size)*3.5f, (y+y+1-size)*2.3f, -50f )
			ar.Add(ec)
			ec.store.vbo.Add( makeTexCoord(x,y) )
		# remove original
		(ec = ar[0]).visible = false
		ec.tags.RemoveAll() do(t as kri.ITag):
			t2 = t as support.pick.Tag
			return t2 != null
