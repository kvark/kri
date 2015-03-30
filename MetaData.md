# Introduction #

Material is basically a surface description. It allows some _Render_ to choose a proper way to draw the mesh using this surface. Pure engines let material decide how to draw itself. More advanced ones allow Renders to exploit surface properties by constructing custom shaders (see [RenderPipeline](RenderPipeline.md)).

A traditional material contains the following information:
  * Colors: emissive, diffuse, specular, ambient
  * Scalars: diffuse reflection, specularity, glossiness, parallax amount
  * Maps: texture, bump, reflection

Material parameters fit well the OpenGL fixed-function pipeline. However, adding new feature to the material becomes a problem when the structure is fixed. Meta data concept is designed to handle arbitrary material data in a user-defined way.


# Generalizing material data #

Programmable GPU pipeline provided by pure GL-3 context is a good background for handling arbitrary material parameters. Only the following components have to be aware of some material data:
  * Loader/Factory: to load it into the material
  * Render: to use it in the constructed shader (only interface is required)

The concept of _Meta-data_ makes the material to be just a holder of the meta-data list. Engine doesn't know about what's inside. Recent changes in the engine allow meta-data to hide used textures, freeing the core of texture units control. The meta-data now can read from a texture transparently, providing the access to various baking techniques starting from a simple diffuse texture and ending in a texture pre-calculated functions for the light model implementations. The life cycle of meta-data goes through the following stages:
  1. Created by loader/factory. Put inside a material.
  1. The owned shader is attached to some program. Asked for links to the other meta-data.
  1. The uniform parameter dictionary is provided to link against. (see [ShaderParam](ShaderParam.md))
  1. Value is set and read repeatedly by the shader parameter representors.

This way parameters are hidden inside the meta-data and assigned transparently to corresponding shader uniforms. Meta-data may export a shader that implements a hidden mechanics. Render as a meta-user has to know about this functionality interface and construct its shaders accordingly.

```

#---	Named meta-data with shader		---#
public class Hermit(IBase,IShaded):
	[Property(Name)]
	private name	as string	= ''
	[Property(Shader)]
	private shader	as Object	= null

	public def copyTo(h as Hermit) as Hermit
	def IBase.clone() as IBase
	def IBase.link(d as rep.Dict) as void


#---	Advanced meta-data with unit link	---#
public class Advanced(IAdvanced,Hermit):
	[Property(Unit)]
	private unit	as AdUnit	= null
	def IBase.clone() as IBase


#---	Unit representor meta data with no shader	---#
public class AdUnit( IBase, par.Value[of kri.Texture] ):
	public input	as Hermit		= null
	public final pOffset	as par.Value[of Vector4]
	public final pScale	as par.Value[of Vector4]
	
	public def constructor(s as string)
	def IBase.clone() as IBase
	def IBase.link(d as rep.Dict) as void


#---	real value meta-data	---#
# used for material diffuse,specular,emissive & glossiness components

public class Data[of T(struct)]( IAdvanced, par.Value[of T] ):
	[Property(Unit)]
	private unit	as AdUnit	= null
	[Property(Shader)]
	private shader	as Object	= null

	public def constructor(name as string)
	public def constructor(un as AdUnit, sh as Object, pv as par.Value[of T])
	def IBase.clone() as IBase
	def IBase.link(d as rep.Dict) as void


#---	Material as a meta-data holder	---#
public class Material( ani.data.Player ):
	public final name	as string
	public final dict	= shade.rep.Dict()
	public final tech 	= array[of shade.Smart]	( lib.Const.nTech )
	public final metaList	= List[of meta.Advanced]()
	
	public Meta[str as string] as meta.Advanced
	public def constructor(str as string)
	public def constructor(mat as Material)			# clone with all metas
	public def link() as void				# update dictionary
	public def collect(melist as (string)) as shade.Object*	# collect shaders for meta data
```


# Meta Technique #

_Meta-Technique_ (MT) is a render that draws objects surface materials using a specified set of meta-data. For example, emission render requires only 'emissive' meta-data to present, while light render asks for the whole set of lighting properties ('diffuse','specular','glossiness',etc). The material is rejected by MT if some meta-data is not found (the technique program is set to Fixed(id=0)).

Meta-data forms a directed acyclic graph, starting from the material (which also could be converted to meta format if needed). The first layer meta-data may point to the texture meta-unit (second layer). Meta-units have to point to some texture coordinate input meta-data (third layer). The current implementation doesn't support other meta-graph variations, but the concept does.

The meta-technique passes a list of meta-data names to the material, collecting all shaders from the required sub-meta-graph. These shader objects are attached to constructed program, which is linked using material's uniform dictionary (among others). This dictionary is filled with all meta-data shader parameters that present upon material construction (and can be updated at any time).

```
public class Meta(General):
	private final lMets	as (string)
	private final lOuts	as (string)
	protected shobs			= List[of kri.shade.Object]()
	protected final dict	= kri.shade.rep.Dict()
	private final factory	= kri.shade.Linker(\
		kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
	
	protected def constructor(name as string, outs as (string), *mets as (string))
	protected def shade(prefix as string) as void

	private override def construct(mat as kri.Material) as kri.shade.Smart:
		sl = mat.collect(lMets)
		return kri.shade.Smart.Fixed	if not sl
		return factory.link( sl, mat.dict )
```

This interface provides an easy way to create your own renders:
```
public class Emission( tech.Meta ):
	public backColor	= Color4.Black	
	public def constructor():
		super('mat.emission', null, 'mat_emissive')
		shade('/mat_base')
	public override def process(con as Context) as void:
		con.activate()
		con.ClearColor( backColor )
		drawScene()
```


## Batching ##

_Batch_ is a low-level rendering primitive. Traditionally it refers a mesh and a material to draw. Sorting batches by material before drawing helps to minimize state switches while drawing the same scene.
  1. Loader/Factory creates a meta-data and puts it into the material.
  1. Meta-technique is given a meta ID list, it asks a material to collect required shaders, then links the program
  1. -//- disintegrates the entity into batches, filling their meta list with data taken from the material
  1. Batch activates the shader which smartly updates all used parameters values
  1. Shader code uses meta data of the material


# Conclusion #

It's flexible: a user can load arbitrary data into the material and render it in a desired way. The specific material logic is completely hidden from the engine core and becomes a _Loader & Render_ secret. More than that, the render doesn't know about the fact that some meta-data uses a texture some specific texture coordinates for it. All the render knows is the function signature(s) in the requested meta-data shader.