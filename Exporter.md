## Introduction ##

The engine is just a processor of some input data that produces a beautiful dynamic picture at each frame. The input data includes:
  * **Meshes** (vertex position, orientation, texture coordinate)
  * **Materials** (diffuse/specular/emissive color, textures)
  * **Objects** (entity, camera, light, skeleton, particles)
  * **Structure** (hierarchy, connections)
  * **Animations** (skinning, morphing)

This data is usually created in the 3D editor. Blender is a powerful free multi-platform 3D editor that provides an open scripting interface. My Python script not only writes 3d data to a binary file, but also transforms it in a way the engine likes to see it.


## Usage ##

Just copy the _{kri}/export/io\_scene\_kri_ folder to the _{blender-data}/scripts/addons/_ on your machine. Reload Blender to see the changes (or press F8). You may also be requred to go to Blender user prefereces and check a box to the side of "Kri Scene" addon to enable it.

Load the scene and go to _File/Export/Scene KRI..._. Choose a path to the scene exported file and click '_Export KRI_' button. The Blender console window will show you the detailed statistics of the export with the enumeration of objects, animations and warnings (if any).

### Options ###

'_Process quaternions_' flag enables the special processing that guarantees the correct linear quaternion interpolation across each polygon of a mesh. It's required for baking to UV, deferred shading and advanced lighting calculations (leave it 'on' if you are not sure). The processing will create new vertexes and faces if needed (but not more than required) and report the result to the console.


## Structure ##

The exported file is binary and consists of the sequence of chunks. The chunk structure:
  * (8 bytes) null-terminated chunk name
  * (4 bytes) chunk data size = N
  * (N bytes) chunk-specific data

The loader will read them one by one. Each chunk is loaded by a separate module, which can be attached or replaced by the user at any time. The chunk is skipped if no specific module is found matching the chunk name.

The main idea of exporting chunks is an ability to read as much as you can, skipping minimum of the unknown information at the same time. For instance, the mapping input information is incapsulated in a chunk separate from other texture unit data, because it may contain variable-size data (UV layer, object name or nothing).

A chunk loader may depend on a 'parent' chunk to be processed first (e.g. vertex positions chunk follows the mesh chunk).

| **Name**	| **Purpose**		| **Requirements**	| **Data**		|
|:---------|:-------------|:-----------------|:----------|
| _kri_	| engine identifier	| - (always first)	| version number	|
| _node_	| spatial node		| -			| name, parent name, transformation	|
| _cam_	| camera object	| node			| projector, is active flag		|
| _lamp_	| light object		| node			| color, attenuation, projector	|
| _entity_	| entity object	| node,mesh		| material link	|
| _part_	| particle emitter	| node/entity		| name, material name, distribution, lifetime, velocity, force, size	|
| _mat_	| material		| -			| name, colors, shading params		|
| _tex_	| texture slot		| mat			| target, gentype, mapping, image path	|
| _mesh_	| mesh			| -			| verts number		|
| _v\_pos_	| vertex positions	| mesh			| nVx vector3		|
| _v\_quat_	| vertex orientations	| mesh			| nVx quternion	|
| _v\_uv_	| texture coordinates	| mesh			| nVx vector3		|
| _v\_skin_	| skin weights		| mesh			| nVx 4x ushort	|
| _v\_ind_	| polygon indeces	| mesh			| polys number, nPx 3x ushort		|
| _skel_	| skeleton		| node			| bones number, nBx (name, parent id, transformation)		|
| _action_	| universal action	| player		| name, time		|
| _curve_	| animation curve	| action		| data path, element size, sub id, sequence of values	|


## Additional work ##

### Quaternion calculation ###

The engine is designed to operate with quaternions instead of matrices (see [Quaternions](Quaternions.md)). The quaternions are produced in the following steps:
  1. For each face the tangental space is constructed based on UV coordinates (tangent = U, bitangent = V). The tangent with the handness bit are kept.
  1. For each vertex the tangent are averaged from the faces that use it, having the face's surface amount as a weight.
  1. The averaged tangent, original vertex normal and the handness bit produce the tangental space matrix. This matrix is orthonormal and right-handed. It's converted to the quaterion that is exported in a separate vertex attibute, while the handness bit is placed in the texture coordinate's Z channel.


### Vertex attributes merging ###

For the 3D editor a vertex may have different UV and normals for each face it belongs to. For the OpenGL pipeline a vertex has to be supplied with all the data required for it's processing: vertex attributes. Hence, the script makes as few GL vertices as possible for a given set of Blender vertexes and faces. The algorithm is the following:
  1. collect all vertex per face (VPF) data: each Blender vertex will spawn a VPF for each face it belongs
  1. distribute VPFs into the map, where the key is a tuple (position, orientation, texture coordinate, face handness)
  1. form a resulting set of vertexes taking a single VPF per unique key
  1. update face indices to point to the correct vertex instead of the original Blender vertex


### Quaternions processing ###

One of the quaternion problems is that the representation is always a constant-handed matrix, hence the script exports the handness bit in addition.

The other problem happens in the linear interpolation, because the _Q_ and _-Q_ (component-wise) both represent the same transformation. So, given the same transformation with different quaternion sides will yield a complete arc during the interpolation, while it should be just constant.

The task of this (optional) stage is to make sure that for each face the 3 quaternions will be linearly interpolated correctly when going from a vertex to a fragment shader by the hardware. This is formulated as _dot(qi,qj)>0_ for _i,j_ in {0,1,2} (as a product of 4D vectors). According to this equation the script goes through the faces of a mesh and performs some actions to ensure interpolate-ability:
  * 0 negative products = it's good!
  * 1 negative = bad: dividing the face
  * 2 negative = not good: cloning the vertex
  * 3 negative = very bad: going through 2 & 1 cases