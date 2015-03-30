## Attributes ##

Vertex attributes may be stored either together or in separate _VBO_'s.
A collection of attributes is called _AttribStorage_ in _kri_. It consists of a number of _VBO_, each containing a list of vertex attribute declarations.
For the top level the _VBO_ layer is transparent: classes that use _AttibStorage_ generally treat it like a simple attribute container.

In _kri_ attributes are contained in _AttribStorage_:
  * vertex position
  * tangent space orientation
  * texture coordinate

Mesh is derived from it, whereas Entity includes it too in order to store the attributes which supposed to be animated. For example, 2 entities using the same mesh may look different because the mesh is skinned and their skeletons have different time states.
When rendering (see [RenderPipeline](RenderPipeline.md)), the attributes required by a shader are first looked in the entity and then in the corresponding mesh. This behavior guarantees that animated attributes will always be used by Renders.

Loader/factory is free to create whatever _VBO_ it needs for the entity & mesh. This information goes transparently though all drawing functionality, though it's explicitly needed by Transform Feedback.


## Entity ##

In _kri_ entity may consist of different materials to be drawn. This ability allows treating the entity like a logical game object. Before rendering, the entity is divided by batches each having its own piece of the mesh with a single material reference. The material link data is now stored in tags.

The _Node_ reference is used to obtain local->world transformation.

The _Storage_ object contains animated attribute data.

The _VAO_ dictionary is used to store vertex attributes bindings for each rendering technique.

The _Texture_ array may contain various per-object maps, such as dirt (for car simulators), dynamic reflection, global illumination coefficients, etc.


## Tags ##

Tags serve as special attributes of an object (entity). They encapsulate data specific to the correspondent domain operations. Leaving the entity interface clean and tiny, tag system provides a great scalability of entity attributes, which can be implemented easily in the user space.

For example, there is a skinning tag that contains a reference to the skeleton and a state identifier. Only the skinning render is capable of extracting that data from an entity, naturally skipping those without a skinning tag. The tag itself and the update render are placed under a single namespace, interacting with the rest of the engine only in places of loading and manual user interaction.

Currently we have these tags implemented:
  * _mat_: for the material info of the entity
  * _skin_: for skeletal animations
  * _pick_: for mouse picking
  * _bake_: for baking vertex position & orientations into the uv map


## Implementation ##
```
public class Entity( kri.ani.data.Player ):
	public node	as Node		= null
	public mesh	as Mesh		= null
	public visible	as bool	= true
	public final store	= vb.Storage()
	public final va		= Dictionary[of string,vb.Array]()
	public final tags	= List[of ITag]()
	
	public def seTag[of T(ITag)]() as T	# find a tag by the type
	public def enable(ids as int*) as bool	# bake attributes + index
	public def enable(tid as int, ids as int*) as bool:
		va[tid] = vb.Array()
		va[tid].bind()
		return enable(ids)
```