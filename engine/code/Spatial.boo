namespace kri

import System
import System.Collections.Generic
import OpenTK

#------------------------------------------
#	DUAL QUATERNION
#	effectively represents spatial data for the interpolation

public struct DualQuat:
	public re	as Quaternion
	public im	as Quaternion
	public static final Identity = DualQuat( re:Quaternion.Identity,
		im:Quaternion( Xyz:Vector3.Zero, W:0f ) )
	
	public def constructor(ref s as Spatial):
		re = s.rot
		im = Quaternion( Xyz:0.5f*s.pos, W:0f ) * re
	public def lerp(ref s0 as Spatial, ref s1 as Spatial, k as single) as void:
		re	= (1f-k) * s0.rot + k * s1.rot
		pos	= (1f-k) * s0.pos + k * s1.pos
		im	= Quaternion( Xyz:0.5f*pos, W:0f ) * re
	public def toUnitSpatial(ref s as Spatial) as void:
		kn = 1f / re.Length
		s.pos = (2f * kn * kn) * (im * Quaternion.Conjugate(re)).Xyz
		s.rot = kn * re
		
	
#------------------------------------------
#	SPATIAL
#	represents nodes position,rotation & scale in 3D space

public struct Spatial:
	public rot		as Quaternion
	public pos		as Vector3
	public scale	as single
	public static final Identity = Spatial( rot:Quaternion.Identity, pos:Vector3.Zero, scale:1.0f )
	
	public static def Qrot(ref v as Vector3, ref q as Quaternion) as Vector3:
		return (q * Quaternion(Xyz:v,W:0f) * Quaternion.Invert(q)).Xyz
	public static def Lerp(ref a as Spatial, ref b as Spatial, t as single) as Spatial:
		sp as Spatial
		sp.lerpDq(a,b,t)
		return sp

	public def combine(ref a as Spatial, ref b as Spatial) as void:
		rot		= b.rot * a.rot
		scale	= b.scale * a.scale
		pos		= b.byPoint(a.pos)
	public def inverse() as void:
		rot		= Quaternion.Invert(rot)
		scale	= 1f / scale
		pos	= -scale * Vector3.Transform(pos,rot)
	public def lerp(ref a as Spatial, ref b as Spatial, k as single) as void:
		rot		= Quaternion.Slerp(a.rot, b.rot, k)
		scale	= (1f-k)*a.scale + k*b.scale
		pos		= Vector3.Lerp(a.pos, b.pos, k)
	public def lerpDq(ref a as Spatial, ref b as Spatial, k as single) as void:
		scale	= (1f-k)*a.scale + k*b.scale
		dq as DualQuat
		dq.lerp(a,b,k)
		dq.toUnitSpatial(self)
	public def byPoint(ref v as Vector3) as Vector3:
		return pos + scale * Vector3.Transform(v,rot)


#------------------------------------------
#	BONERECORD, BONECHANNEL, ANIDATA
#	animation primitives

public class BoneChannel2( ani.data.Channel[of Spatial] ):
	public def constructor(index as byte, num as int):
		super(num) do(pl as ani.data.IPlayer, val as Spatial):
			bar = (pl as Skeleton).bones
			bar[index].setPose(val)	if index < bar.Length
		self.lerp = Spatial.Lerp


public struct BoneRecord( IComparable[of BoneRecord] ):
	public d as Spatial
	public t as single
	public def CompareTo(r as BoneRecord) as int:	#imp: IComparable
		return t.CompareTo(r.t)

public struct BoneChannel:
	public final b	as byte
	public final c	as (BoneRecord)
	public def constructor(index as byte, num as int):
		assert num>0
		b, c  =  index, array[of BoneRecord](num)
	public def moment(time as single) as Spatial:
		i = Array.FindIndex(c) do(ref r as BoneRecord):
			return r.t > time
		return c[-1].d	if i < 0
		return c[0].d	if not i
		s = Spatial()
		k = (time - c[i-1].t) / (c[i].t - c[i-1].t)
		s.lerpDq(c[i-1].d, c[i].d, k)
		return s

public class AniData:
	public final name		as string
	public final length		as single
	public final channels	= List[of BoneChannel]()
	public def constructor(str as string, t as single):
		name,length = str,t


#------------------------------------------
#	NODE
#	hierarchy element in space
#	has a parent, caches the world-space transform

public class Node( IComparable[of Node] ):
	public final name	as string
	public final anims	= List[of AniData]()
	private parent	as Node = null
	private local	= Spatial.Identity
	private cached	= Spatial.Identity
	private world	= Spatial.Identity
	
	public def constructor(str as string):
		name = str
	public def constructor(n as Node):
		name = n.name
		parent = n.parent
		local = n.local
	#TODO: explicit interface imp, when supported
	public def CompareTo(n as Node) as int:	#imp: IComparable
		return name.CompareTo(n.name)
	public def refresh() as void:
		world.combine(local,cached)
	public def find(str as string) as AniData:
		return anims.Find({d| d.name == str })
	
	public Parent as Node:
		get: return parent
		set:
			parent = value
			return	if not value
			cached = parent.World
			refresh()
	public Local as Spatial:
		get: return local
		set:
			local = value
			refresh()	
	public World as Spatial:
		get:
			if parent:
				pw = parent.World
				if pw != cached:
					cached = pw
					refresh()
				return world
			else:	return local
	

#------------------------------------------
#	NODEBONE
#	bone node with pose sub-space

public class NodeBone(Node):
	public final bindPose	as Spatial
	private invWorldPose	as Spatial
	public pose	= Spatial.Identity
	
	public def constructor(str as string, ref initPose as Spatial):
		super(str)
		Local = bindPose = initPose

	public def Clone() as Object:	#imp: ICloneable
		s = bindPose
		n = NodeBone(name,s)
		n.Parent = Parent
		n.Local = Local
		return n
	public def setPose(s as Spatial) as void:
		rez = p = bindPose
		rez.combine(s,p)
		Local = rez
	public def setPose() as void:
		rez = bp = bindPose
		rez.combine(pose,bp)
		Local = rez
	public def genTransPose(ref sloc as Spatial, ref sp as Spatial) as void:
		sp.combine(sloc,invWorldPose)	# object local -> pose
	public def bakeInvPose(ref s as Spatial) as void:
		pp = World
		pp.inverse()
		invWorldPose.combine(s,pp)


#------------------------------------------
#	SKELETON
#	manages bones

public class Skeleton( ani.data.Player ):
	public final bones	as (NodeBone)
	public final node	as Node
	[getter(State)]
	private state		as int	= 0
	
	public def constructor(n as Node, num as int):
		node = n
		bones = array[of NodeBone](num)
	public def constructor(s as Skeleton):
		node = s.node
		bones = s.bones.Clone() as (NodeBone)
		for i in range( bones.Length ):
			par = bones[i].Parent
			continue	if not par
			ind = Array.IndexOf(s.bones, par)
			#ind = Array.BinarySearch(s.nodes, par)
			continue	if ind < 0
			bones[i].Parent = bones[ind]

	def ani.data.IPlayer.touch() as void:
		for b in bones:
			b.setPose()
		++state
	public def bakePoseData(np as Node) as void:
		sw = np.World
		for b in bones:
			b.bakeInvPose(sw)
		++state
	public def reset() as void:
		for b in bones:
			b.pose = Spatial.Identity
			b.Local = b.bindPose
		++state
	public def moment(t as single, sd as AniData) as void:	# absolete
		for c in sd.channels:
			continue	if c.b > bones.Length
			sp = c.moment(t)
			if not c.b: node.Local = sp
			else: bones[c.b-1].setPose(sp)
		++state
