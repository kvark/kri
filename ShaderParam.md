# Introduction #

Fixed-function pipeline is deprecated in _OpenGL-3 / ES-2_. Everything requires a shader to draw. Each shader demands the following data ready for it's execution:
  * _Vertex attributes_ bounded to some slots and associated with concrete names.
  * _Texture units_ bounded to slots and associated with appropriate _Uniform_ names.
  * All _Uniform_ parameters are applied. May include light & material data, spatial transformations, etc.

The set of required data is defined by the shader code and don't change during the lifetime of the program therefore. It would be perfect to have an ability to specify this data at the time of shader creation.

In _KRI_ the shader contains a list of parameter representors. They upload uniform/texture unit data as needed upon shader execution. The shader has also uniform location -> public data source mapping (such as vectors, floats, etc) that is changed by the user/engine. For each representor, the actual data source is associated by the uniform location, but stored intependently. Its required when we want to use the same (already linked) program for another set of data sources (for example, another material): the representors are kept, while the data sources are copied over and some of them changed.

# Details #

The base class for representors:
```
public class Base:
	public final loc	as int
	# uniform location
	protected def constructor(id as int):
		loc = id
	# send data to the shader
	public abstract def upload(iv as par.IBaseRoot) as void:
		pass
	# generate an uniform representor
	public static def Create(iv as par.IBaseRoot, loc as int) as Base
```

The smart shader program contains representors and data sources separately.
```
public class Smart(Program):
	private final repList	= List[of rep.Base]()
	private sourceList	as (par.IBaseRoot)

	public def constructor(sa as Smart):
		super( sa.id )
		repList.Extend( sa.repList )
		sourceList = array[of par.IBaseRoot]( sa.sourceList.Length )
		sa.sourceList.CopyTo( sourceList, 0 )

	public override def use() as void:
		super()
		for rp in repList:
			iv = sourceList[ rp.loc ]
			rp.upload(iv)
```

Next, there is a simple parameter class hierarchy:
```
public interface IBaseRoot:
	pass
public interface IBase[of T](IBaseRoot):
	Value	as T:
		get
public interface INamed:
	Name	as string:
		get

public class Value[of T](IBase[of T],INamed):
	[property(Value)]
	private val	as T
	[Getter(Name)]
	private final name	as string
	public def constructor(s as string)
```

Next, there are corresponding classes in the representors hierarchy, that load an actual value into the shader if needed (after checking the equivalence with a cached value, for example):
```
# Uniform representor
public class Uniform[of T(struct)](Base):
	public data	as T
	public def constructor(lid as int):
		super(lid)
	public override def upload(iv as par.IBaseRoot) as void:
		val = (iv as par.IBase[of T]).Value
		if data != val:
			data = val
			Program.Param(loc,data)
		

# Texture Unit representor
public class Unit(Base):
	public final tun	as int
	public def constructor(lid as int,tid as int):
		super(lid)
		Program.Param(lid,tid)
		tun = tid
	public override def upload(iv as par.IBaseRoot) as void:
		tex = (iv as par.IBase[of kri.Texture]).Value
		tex.bind(tun)	if tex
```

## Parameter dictionary ##

When the shader program is being linked, each uniform name has to be associated with existing parameter owned by one of the following substances:
  1. engine (model/light/camera view, light/camera projections)
  1. material (emissive/diffuse/specular color & coefficients)
  1. render, which creates a program (specific, includes non-material texture units)
  1. particle manager
  1. user's custom classes

This association is done via parameter dictionary lookup by the uniform name. The dictionary stores data sources (`par.IBaseRoot` type), that are simply copied to the data source array of the program. When the program is (re)created, the special functionality creates corresponding representors by analysing the source type.

Here is an example of engine-side light parameter storage:
```
public final class Light( IBase ):
	public final color	= par.Value[of Color4]('lit_color')
	public final attenu	= par.Value[of Vector4]('lit_attenu')
	public final data	= par.Value[of Vector4]('lit_data')

	public def activate(l as kri.Light) as void	# getting values from the light
	par.INamed.Name as string
	def IBase.clone() as IBase
	def IBase.link(d as rep.Dict) as void		# register params in the dictionary
```


## Vertex attributes ##

Attributes can be activated in a similar manner, but KRI entities (see [Entity](Entity.md)) are activated by _Vertex Array Object_ which contains some attributes baked in it. So the corresponding VAO is activated by a rendering technique that constructs a shader (see [RenderPipeline](RenderPipeline.md)).