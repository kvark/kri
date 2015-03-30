# Introduction #

This article explains how KRI engine features can be added from the outside. You can find all the extension mechanisms of the engine described here. We will also go step-by-step though a complete example of mesh morphing (shape keys in Blender) being implemented as a separate module.

# Modularity features #

## Exporter ##

You would have to modify some exporter code in order to add functionality to this stage. However, the native scene format has a chunk structure ([Exporter](Exporter.md)), so adding new chunks will not break existing data loading procedure (just make sure you have no name collosions in chunk names). Here is an example of a chunk export:
```
out.begin('t_seq')	# image sequence
out.pack( '3H', user.frames, user.offset, user.start_frame )	# data
out.end()		# finish chunk
```

## Loader ##

Loaders are registered in data managers and keyed by the return type. Here is an example loader of the text files into strings:
```
public class Text( kri.data.ILoaderGen[of string] ):
	public def read(path as string) as string:
		return System.IO.File.ReadAllText(path)
...
loadText = Text()
kri.Ant.Inst.dataMan.register(loadText)
```

### Switch ###

`kri.data.Switch` chooses an approriate loader based on the filename extension. Here is an application example (from Native.boo):
```
	swImage	= kri.data.Switch[of kri.buf.Texture]()
	swImage.ext['.tga'] = image.Targa()
	resMan.register( swImage )	# local data manager
```

## Extension ##

KRI engine has an extension interface. Each extension adds some chunk readers to the native loader upon its construction. These are core extensions added automatically: _ExMaterial_, _ExMesh_, _ExAnim_ and _ExObject_. They can be accessed via engine core: `kri.Ant.Inst.loaders.*`

## Vertex attributes ##

Entity's `store` vertex buffer storage, as well as a corresponding mesh, may contain attributes you put in them. They will be accessed only by the shaders with matching input names and types.

## Entity tags ##

You can add custom tags to entities and use them by your own renderers (see [Entity](Entity.md)).

## Material ##

Material in KRI is a container for meta data (see [MetaData](MetaData.md)). You can have entirely new materials with your own meta-data and renderer techniques accessing them.

## Renderer ##

KRI engine allows compound renderers. You can find a chain renderer (is an analog to a list) and a job scheduler among the standard ones. All of them allows adding custom renderers (derived from `kri.rend.Basic`).

A simple renderer may operate on user-defined vertex attributes.

A render technique may use user-created meta blocks of the material to build its shaders.



# Example: Morphing #

## Export ##

The following code has been added to mesh exporting routine:
```
	for sk in (shapes.keys if mesh.shape_keys else []):
		out.begin('v_shape')
		# write shape key data
		out.end()
```


## Entity ##

A tag class has been implemented to hold shape key data:
```
public class Tag( kri.ITag ):
	public final name	as string
	public final data	= kri.vb.Attrib()
	public relative	as Tag		= null
	[Getter(Dirty)]
	private dirty	as bool		= false
	private val		as single	= 1f
	public Value	as single:
		get: return val
		set: dirty=true; val=value
	public def constructor(s as string):
		name = s
```


## Loader ##

An extension class has been implemented. It should be registered by a user who wishes to load morph data.
```
public class Extra( kri.IExtension ):
	private def racShape(pl as kri.ani.data.IPlayer, v as single, i as byte):
		keys = (pl as kri.Entity).enuTags[of Tag]()
		keys[i-1].Value = v
	# implementing IExtension
	def kri.IExtension.attach(nt as kri.load.Native) as void:
		nt.readers['v_shape']	= pv_shape	# register loader
		anil = kri.Ant.Inst.loaders.animations	# register animation channel
		anil.anid['v.value']	= kri.load.ExAnim.Rac(getReal,racShape)
	# shape chunk loader
	public def pv_shape(r as kri.load.Reader) as bool:
		e = r.geData[of kri.Entity]()	# get current entity
		if not (e and e.mesh):	return false
		tag = Tag( r.getString() )	# create a shape key tag
		r.getByte()
		tag.Value = r.getReal()		# read tag data
		ar = kri.load.ExMesh.GetArray[of Vector3]( e.mesh.nVert, r.getVector )
		tag.data.init(ar,false)		# fill tag data
		kri.Help.enrich( tag.data, 3, 'vertex' )
		e.tags.Add(tag)			# add to the entity
		return true
```


## Update ##

The `Update` renderer does all the hard work of interpolating between shape keys in a shader. Refer to the actual source for details (support/morph).
```
public class Update( kri.rend.Basic ):
	public def constructor():
		pass # make shader
	public override def process(con as kri.rend.link.Basic) as void:
		for ent in kri.Scene.Current.entities:
			keys = ent.enuTags[of Tag]()
			# 1. check validity of the keys and the entity
			# 2. assign vertex attributes
			# 3. draw the mesh with transform feedback
```


## Animation ##

There is a custom animation class designed to shift morphing coefficients. This animation should be played with an active update renderer in order to see the effect on the object.
```
public class Anim( kri.ani.Loop ):
	public final k0	as Tag
	public final k1	as Tag
	public def constructor(e as kri.Entity, s0 as string, s1 as string):
		assert s0 and s1 and s0!=s1
		k0 = k1 = null
		for key in e.enuTags[of Tag]():
			k0 = key	if key.name == s0
			k1 = key	if key.name == s1
		assert k0 and k1
	protected override def onRate(rate as double) as void:
		k0.Value = 1.0 - rate
		k1.Value = rate
```


## User ##

This is a part of a typical user code that takes an advantage of the Morph module:
```
using win = kri.Window('kri.conf',0):
	# read the scene
	win.core.extensions.Add(support.morph.Extra())	# register an extension
	ln = kri.load.Native()
	at = ln.read('res/test_hair.scene')		
	ent = at.scene.entities[0]
	# add renderer
	view = kri.ViewScreen()
	rchain = kri.rend.Chain()
	view.ren = rchain
	win.views.Add( view )
	rchain.renders.Add( support.morph.Update() )
	# add an animation
	win.core.anim = al = kri.ani.Scheduler()
	morphNative = true	# programmable action
	morphExport = false	# exporter data curve
	if morphNative:
		amorph = support.morph.Anim(ent,'Basis','Key 1')
		amorph.lTime = 10.0
		al.add( amorph )
	elif morphExport:
		al.add( ent.play('Action') )
	# main loop
	win.Run(20.0,20.0)
```