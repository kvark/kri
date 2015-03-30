# Technology backend #

| **Method**		| **Device**	| **Device Load**	| **Bandwidth load**	| **Limitations**			|
|:------------|:-----------|:----------------|:-------------------|:------------------|
| Regular		| Central	| High			| High			| _No_, flexible weights		|
| On-Fly		| Graphics	| Low-High		| _Low_		| number of passes, vertex count	|
| Transform Feedback	| Graphics	| _Low_		| _Low_		| support: TF/GL-3;			|
| Texture processing	| Graphics	| _Low_		| _Low_		| support: PBO,MRT; video memory	|
| Computing Language	| _Any_	| Low-Medium		| Low-High		| support: OpenCL; flexible load	|

_Remark_: all GPU-based methods can benefit from pure GPU collision detection methods. Using CPU for collisions reduces performance and quality in this case.


# Usage #

A skinned entity has a special tag (of type _kri.kit.skin.Tag_) that contains a link to a skeleton and a current synchronization value.

A skeleton contains bones and animations.

A skin animation (_kri.kit.skin.Anim_) just passes the timer and current channel data into _Skeleton.moment_ routine.


## Processing ##
The transformation work is done in the special render (_kri.kit.skin.Update_) that uses _Transform Feedback_ for processing the vertex data. Transformed vertex positions and orientations (_at\_vert + at\_quat_) are stored in the entity's own _VBO_'s, so the render requires them to exist at the time of processing. There is a special function (_kri.kit.skin.prepare_) for creating these attributes and adding a proper tag to the entity.


## Modification ##
Bones are nodes, and you can change their transformation freely. Just don't forget to call _Skeleton.touch_ in order to synchronize correctly with linked entities.

The parenting can also be changed but requires call to _Skeleton.bakePoseData_ in the end.


## Sharing ##
A skeleton can be shared playing the same animation simultaneously on all participating entities.

A skeleton can be cloned, allowing playing different animation or phase on the entity. Cloned skeletons share animation data but don't share bones.


## Interoperation ##
When the entity's data is processed, this object can not be drawn in any render (in parallel for the graphics conveyer) until the processing finishes. Thus, a consecutive draw call will stall the pipeline and wait for skinning transformation to completely finish.

I recommend making the skin render a dependency for z-cull render (which is usually the first one). This will cause a stall but provide correct data for farther processing, at least, and will not confuse the scheduler.
