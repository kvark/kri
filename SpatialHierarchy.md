# Introduction #

Spatial information is often used for several goals:
  * local->world transformation <sup>[always required]</sup>
  * hard directed links between objects: _A->B->CD_ <sup>[covers 90% of physics joints actually used]</sup>
  * implicit container interface for objects <sup>[bad intention to use it for holding logical links information]</sup>
  * hierarchical visibility/pickability restrictions & drawing order <sup>[even worse intention of combining different scene interfaces on the spatial level]</sup>

As you can see, the purpose of spatial structures is often misunderstood. It's always a temptation for a programmer to use one hierarchy for everything. But the more it's shared, the less scalability and usability it provides.


# Details #

Spatial structure is often implemented by the Node element containing:
  * pointer to the parent node
  * list of pointers to children nodes
  * local transformation info + cached world transform
  * set of state flags that automatically affect children

The major problem of this structure is **redundancy**. Each node is referred by parent and its children at the same time, what makes it more difficult to support the consistency of the hierarchy. Some programmers need an ability to scan all the tree at once, iterate through the children objects, but I don't think it's really needed. Pointing the parent is enough for the recursive calculation of the world transform as well as for the reconstruction of the whole spatial tree if needed (even once per frame is not so expensive).

I'm rejecting the ability to go down the tree combining transformations. Instead, each node can ask parent for its transform if needed and use cache more effectively. Flags are not needed as well as they generally represent scene interfaces. The final Node structure is much simpler: it contains only a link to the parent and the transformation data.

It's often the case that programmers combine spatial information inside the object. It fits the logical structure usage pattern (container interface) pretty well. However, it makes the definition of an object more complex. It's much easier to distinguish these terms into just Nodes and just Game Objects. The latter should just contain a pointer to the Node and use it **only** for retrieving the world transformation when needed. This way all the spatial links become transparent to the Game Object.


## Spatial implemetation _(Boo+OpenTK)_ ##

```
public struct Spatial:
	public rot		as Quaternion
	public pos		as Vector3
	public scale	as single
	public static final Identity = Spatial( rot:Quaternion.Identity, pos:Vector3.Zero, scale:1.0f )
	
	# vector * quaternion is still not supported by OpenTK... waiting for the update
	public static def rotQuat(t as Quaternion, ref q as Quaternion) as Quaternion:
		return Quaternion.Mult( Quaternion.Mult(q,t), Quaternion.Invert(q) )
	public static def rotVector(ref v as Vector3, ref q as Quaternion) as Vector3:
		return rotQuat( Quaternion(Xyz:v,W:0.0),q ).Xyz

	public def combine(ref a as Spatial, ref b as Spatial) as void:
		rot		= b.rot * a.rot
		scale	= b.scale * a.scale
		pos		= b.byPoint(a.pos)
	public def inverse() as void:
		rot		= Quaternion.Invert(rot)
		scale	= 1.0f / scale
		pos		= rotVector(pos,rot)
		pos.Mult(-scale)
	public def lerp(ref a as Spatial, ref b as Spatial, k as single) as void:
		rot		= Quaternion.Slerp(a.rot, b.rot, k)
		scale	= (1.0f-k)*a.scale + k*b.scale
		pos		= Vector3.Lerp(a.pos, b.pos, k)
	public def lerpDq(ref a as Spatial, ref b as Spatial, k as single) as void:
		scale	= (1.0f-k)*a.scale + k*b.scale
		dq as DualQuat
		dq.lerp(a,b,k)
		dq.toUnitSpatial(self)
	public def byPoint(ref v as Vector3) as Vector3:
		w = rotVector(v, rot)
		w.Mult(scale)
		w.Add(pos)
		return w
```
See [Quaternions](Quaternions.md) for more info.


## Node implementation _(Boo+OpenTK)_ ##
```
public class Node( kri.ani.data.Player, IComparable[of Node] ):
	public final name	as string
	private parent	as Node = null
	private dirty	= true
	public local	= Spatial.Identity
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
	public def touch() as void:	#imp: IPlayer
		dirty = true
	
	public Parent as Node:
		get: return parent
		set:
			parent = value
			return	if not value
			cached = parent.World
			touch()
	public World as Spatial:
		get:
			if parent:
				pw = parent.World
				if dirty or pw != cached:
					cached = pw
					world.combine(local,pw)
				dirty = false
				return world
			else:	return local
```


## Bones & Skeletons ##

Bones are often treated in a specific manner, implemented by special classes and used inside the skeleton. At the same time they have the same meaning as regular Nodes: just contain spatial transformation. In the 3-rd iteration I decided to implement bones on top of _Node_ class, making as little difference as possible. Currently Bones are the regular part of spatial hierarchy: you can attach any object to a bone without even knowing it's a bone :)

```
public class NodeBone(Node):
	public final bindPose	as Spatial
	private invWorldPose	as Spatial
	
	public def constructor(str as string, ref initPose as Spatial):
		super(str)
		local = bindPose = initPose
	public def constructor(nb as NodeBone):
		super(nb)
		local = bindPose = nb.bindPose

	public def genTransPose(ref sloc as Spatial, ref sp as Spatial) as void:
		sp.combine(sloc,invWorldPose)	# object local -> pose
	public def bakeInvPose(ref s as Spatial) as void:
		pp = World
		pp.inverse()
		invWorldPose.combine(s,pp)
```


# Conclusion #

  * Node structure must be used only for retrieving the local->world transform.
  * Nodes may have arbitrary link types between each other without any support from the logic of the game _(only hard links are supported at the moment)_.
  * Spatial structure must not be overloaded with any container/scene interfaces.
  * Node element must only refer to the parent without any cross-referencing.