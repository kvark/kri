# Introduction #

There are three major approaches of representing the transformation in 3D space:
  1. **Matrix4**, containing _position_, _orientation_, arbitrary _scale_ and even _projection_ info at once. It might be very difficult to use as transforms are strongly mixed inside the matrix, just position is separated. There are often separate methods provided for user-friendly orientating, scaling & positioning. That makes the implementation more complex and less transparent, introducing additional CPU overhead on user interaction.
  1. **Matrix3** + **Vector3**, where the first represents _rotation_ + _scale_ and the second is  just a _position_. It doesn't have any perspective information, and we don't really need it. It's more friendly and fast (especially in matrix inversion & multiplication), but still hard to use as this approach is hybrid.
  1. **Quaternion** + **Vector3** + **Float**, representing _orientation_, _position_ & _scale_ correspondingly. This interface perfectly fits user needs, and the obstacles can be bypassed. (see [SpatialHierarchy](SpatialHierarchy.md),[Exporter](Exporter.md))


# Details #

As you can see, I accept only the last variant. Here are the major properties:
  * No need for the additional layer between engine & user. You can modify spatial values directly (only _dirty_ flag requires to be maintained for caching).
  * 2x less memory/bandwidth load. _Position+Scale_ forms one _Vector4_ forming two vectors with _Quaternion_ for a complete spatial data. _Tangent+Normal_ supplied per vertex are replaced by a single quaternion with no need for Bitangent computation.
  * Combining transformations is much cheaper (including inversion & multiplication), while applying them can be more expensive (2 cross products at least). The situation may change radically when GLSL gains support for quaternions.
  * Uniform scale limits user somewhere in graphics design, but in most cases can be bypassed, e.g. by modifying the mesh itself or writing custom rendering shaders. On the other hand it makes engine computations more solid & stable.

Shader library implementation:
```
struct Spatial	{
	vec4 pos,rot;
};
//rotate vector
vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
//rotate vector (alternative)
vec3 qrot_2(vec4 q, vec3 v)	{
	return v*(q.w*q.w - dot(q.xyz,q.xyz)) + 2.0*q.xyz*dot(q.xyz,v) + 2.0*q.w*cross(q.xyz,v);
}
//combine quaternions
vec4 qmul(vec4 a, vec4 b)	{
	return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}
//inverse quaternion
vec4 qinv(vec4 q)	{
	return vec4(-q.xyz,q.w);
}
//perspective project
vec4 get_projection(vec3 v, vec4 pr)	{
	return vec4( v.xy * pr.xy, v.z*pr.z + pr.w, -v.z);
}
//transform by Spatial forward
vec3 trans_for(vec3 v, Spatial s)	{
	return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
}
//transform by Spatial inverse
vec3 trans_inv(vec3 v, Spatial s)	{
	return qrot( vec4(-s.rot.xyz, s.rot.w), (v-s.pos.xyz)/s.pos.w );
}
```


## Perspective transform ##

Perspective should not be used as a regular object transform. It's performed in separate stage when we need to project the world on the camera/light. This transformation also uses homogeneous vector representation, while other transformations don't. Therefore, it's a right decision to move the perspective out of spatial transform capabilities. In order to produce it we just need to pass the _`tan(fov/2)`_ value to the shader and apply it manually for _W_ component computation of _`gl_Position`_ variable.

Implementation in vertex shader:
```
in vec4 at_vertex;	//vertex position
uniform vec4 proj_cam;	//projection data
//spatial transforms to world coordinate system
uniform struct Spatial	{
	vec4 pos,rot;
}s_model,s_lit,s_cam;
...
//object space
vec3 v = trans_for(at_vertex, s_model);
//world space
vec3 vc = trans_inv(v, s_cam);
//camera space
gl_Position = get_projection(vc, proj_cam);
//projection space
```


## Tangent space ##

The tangent space is used for producing correct normal mapping on skinned characters & landscapes. Actually I use it for everything as it's more general case as opposed to object space normal maps. In order to compute it we need to calculate lighting in tangent space. Therefore, to-Camera and to-Light vectors have to be transformed from the object space to tangent space.

It's often performed by 3x3 orthonormal matrix of tangent-bitangent-normal, that is computed per vertex. Surprisingly I came to idea that this representation is very redundant. Maintaining the orthonormality of this matrix is much more difficult than having just a quaternion for that. There is no need for _Normal_ and _Tangent_ vectors supplied for each mesh vertex, all we need is just a quaternion+handness that represent tangent space orientation.

Implementation in vertex shader:
```
in vec4 at_vertex;	//vertex position
in vec4 at_quat;	//tangent space orientation
out vec3 v2light,v2cam;
//spatial transforms to world coordinate system
uniform struct Spatial	{
	vec4 pos,rot;
}s_model,s_lit,s_cam;

...
// light information in world space
vec3 v = trans_for(at_vertex, s_model);
vec3 v_lit = s_lit.pos.xyz - v; //to-Light vector
vec3 v_cam = s_cam.pos.xyz - v; //to-Camera vector

// world -> tangent space transform
vec3 hand = vec3(at_vertex.w, 1.0,1.0);
vec4 quat = qinv(qmul( s_model.rot, at_quat ));
v2lit = hand * qrot(quat, v_lit);
v2cam = hand * qrot(quat, v_cam);
```


# Conclusion #

There is no strong need for matrices in the GL-3 world. I'm performing all spatial transformations using quaternions on CPU as well as on GPU using GLSL shaders. Sacrificing the non-uniform scale leaves many potention problems behind from the start, saving the bandwidth load at the same time. Even more efficiensy can be achieved when GLSL finally gains native support for quaternion operations.
