## Artist side ##

Starting from version 2.5 Blender has a universal animation mechanics based on Bezier curves. It works as follows:
  1. each scene node object (entity, camera, light, armature, etc) has a set of actions
  1. each action is a set of Bezier curves each controlling as single floating point value
  1. each curve has a data path to the value it controls (as string like `pose.bones[3].location`) together with ID of the actual component inside (location has 3 components, etc)

An artist is able to animate any of the parameters as there is no need to enumerate them inside: they will be addressed by the data path string, so granting support for any future objects and properties.


## My goal ##

  * export everything blender has
  * group curves by values and export/load into the actual data structures (quaternions, vectors, colors), but no floats (much easier to maintain)
  * minimal effort on the animation types extensions
  * zero effort for playing the animations


## Implementation ##

The exporter gathers animations of the selected data nodes, groups them by data values and exports each Bezier curve key in format:
```
public struct Key[of T(struct)]:
	public t	as single	# time moment
	public co	as T		# actual value
	public h1	as T		# bezier handle-left
	public h2	as T		# bezier handle-right
```

Keys are grouped by channels (curves). Each channel has 2 special functions:
  * lerp: for interpolation between key values (for example, quaternions use spherical instead of bezier)
  * fup: for uploading the resulting value to the corresponding data slot (for example, access a texture unit of the material and setup its offset to the value)

```
public class Channel[of T(struct)](IChannel):
	public final kar	as (Key[of T])
	# proper callable definitions in generics depend on BOO-854
	public final elid	as byte
	public final fup	as callable	#(IPlayer,T,byte)
	public lerp		as callable = null	#(ref T, ref T,single) as T
	public bezier		as bool	= true
	public extrapolate	as bool	= false
	
	public def constructor(num as int, id as byte, f as callable)
	public def moment(time as single) as T

	def IChannel.update(pl as IPlayer, time as single) as void:
		fup(pl, moment(time), elid)
```


## User side ##

The user sees all animated classes inherited from _Player_ class:
```
public class Record:
	public final name		as string
	public final length		as single
	public final channels	= List[of IChannel]()
	public def constructor(str as string, t as single):
		name,length = str,t

public class Player(IPlayer):
	public final anims	= List[of Record]()
	def IPlayer.touch() as void:
		pass
	public def play(name as string) as Anim:
		rec = anims.Find({r| return r.name == name})
		assert rec and 'Action not found'
		return Anim(self,rec)
```

In order to support custom animations the user needs to do the following:
  1. inherit animated classes from _Player_ (or _IPlayer_)
  1. set up the curve loaders (`Loader.anid[x.some_parameter]`), providing the read function (can be custom) and the value update function
  1. call 'play' method after loading to play the animation :)


## Conclusion ##

Here it is: the engine-transparent animation system, which plays anything you can create in Blender and even more!

Currently the following classes are derived from _Player_:
  * _Node_: spatial transformations
  * _Skeleton_: skeletal animations (the same as previous, but for bones)
  * _Material_: colors, texture coordinates transformations
  * _Light_: color, energy, attenuation, projector properties
  * _Camera_: projector properties