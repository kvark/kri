namespace kri.load

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics
import kri.ani.data


public class ExAnim( kri.IExtension ):
	public final anid		= Dictionary[of string,callable(Reader) as IChannel]()
	public final badCurves	= Dictionary[of string,byte]()
	
	public def attach(nt as Native) as void:	#imp: kri.IExtension
		init()
		# animations
		nt.readers['action']	= p_action
		nt.readers['curve']		= p_curve
	
	# generate private method wrappers here, to pass to 'rac' function
	wrapper Reader = (getReal,getVec2,getVector,getVec4,getScale,getColor,getQuatRev,getQuatEuler)

	# generates invalid binary format if using generics, bypassing with extenions
	[ext.spec.Method(( Vector3,Quaternion,single ))]
	[ext.RemoveSource()]
	private def genBone		[of T(struct)](fun as callable(kri.NodeBone, ref T)):
		return do(pl as IPlayer, v as T, i as byte):
			bar = (pl as kri.Skeleton).bones
			return if not i or i>bar.Length
			fun( bar[i-1], v )
			bar[i-1].touch()
	
	[ext.spec.Method(( Vector3,Quaternion,single ))]
	[ext.RemoveSource()]
	private def genSpatial	[of T(struct)](fun as callable(ref kri.Spatial, ref T)):
		return do(pl as IPlayer, v as T, i as byte):
			n = pl as kri.Node
			fun( n.local, v )
			n.touch()
	
	private def racMatColor(name as string):
		return rac(getColor)		do(pl as IPlayer, v as Color4, i as byte):
			((pl as kri.Material).Meta[name] as kri.meta.Data[of Color4]).Value = v
	private def racTexUnit(fun as callable(kri.meta.AdUnit) as kri.shade.par.ValuePure[of Vector4]):
		return rac(getVector)	do(pl as IPlayer, v as Vector3, i as byte):
			fun((pl as kri.Material).unit[i-1]).Value = Vector4(v)
	private def racProject(fun as callable(kri.Projector,single)):
		return rac(getReal)		do(pl as IPlayer, v as single, i as byte):
			assert not i
			fun(pl as kri.Projector, v)

	# fill action dictionary
	private def init() as void:
		# skeleton sub-trans
		def fs_pos(b as kri.NodeBone, ref v as Vector3):
			b.local.pos = b.bindPose.byPoint(v)
		def fs_rot(b as kri.NodeBone, ref v as Quaternion):
			b.local.rot = b.bindPose.rot * v
		def fs_sca(b as kri.NodeBone, ref v as single):
			b.local.scale = b.bindPose.scale * v
		# spatial sub-trans
		def ft_pos(ref sp as kri.Spatial, ref v as Vector3):
			sp.pos = v
		def ft_rot(ref sp as kri.Spatial, ref v as Quaternion):
			sp.rot = v
		def ft_sca(ref sp as kri.Spatial, ref v as single):
			sp.scale = v
		# projector sub-trans
		def fp_prin(pr as kri.Projector, v as single):
			pr.rangeIn = v
		def fp_prout(pr as kri.Projector, v as single):
			pr.rangeOut = v
		# skeleton bone
		anid['s.location']				= rac( getVector,	genBone(fs_pos) )
		anid['s.rotation_quaternion']	= rac( getQuatRev,	genBone(fs_rot) )
		anid['s.scale']					= rac( getScale,	genBone(fs_sca) )
		# node
		anid['n.location']			= rac( getVector,		genSpatial(ft_pos) )
		anid['n.rotation_euler']	= rac( getQuatEuler,	genSpatial(ft_rot) )
		anid['n.scale']				= rac( getScale,		genSpatial(ft_sca) )
		# material
		anid['m.diffuse_color']		= racMatColor('diffuse')
		anid['m.specular_color']	= racMatColor('specular')
		# texture unit
		anid['t.offset']		= racTexUnit({u| return u.pOffset })
		anid['t.scale']			= racTexUnit({u| return u.pScale })
		# light
		anid['l.energy']	= rac( getReal,		{pl,v,i| (pl as kri.Light).energy = v })
		anid['l.color']		= rac( getColor,	{pl,v,i| (pl as kri.IColored).Color = v })
		anid['l.clip_start']	= racProject(fp_prin)
		anid['l.clip_end']		= racProject(fp_prout)
		# camera
		anid['c.angle']		= rac(getReal) do(pl as IPlayer, v as single, i as byte):
			(pl as kri.Camera).fov = v*0.5f
		anid['c.clip_start']	= racProject(fp_prin)
		anid['c.clip_end']		= racProject(fp_prout)
		# shape key
		anid['v.value']		= rac(getReal) do(pl as IPlayer, v as single, i as byte):
			keys = (pl as kri.Entity).enuTags[of kri.kit.morph.Tag]()
			keys[i-1].Value = v


	#---	Parse action	---#
	public def p_action(r as Reader) as bool:
		player = r.geData[of Player]()
		return false	if not player
		name = r.getString()
		rec = Record( name, r.getReal() )
		player.anims.Add(rec)
		r.puData(rec)
		return true
		
	#---	Channel pre-defined interpolators per type	---#
	private def fixChan(c as Channel_Vector2):
		c.lerp = Vector2.Lerp
	private def fixChan(c as Channel_Vector3):
		c.lerp = Vector3.Lerp
	private def fixChan(c as Channel_Vector4):
		c.lerp = Vector4.Lerp
	private def fixChan(c as Channel_Quaternion):
		c.lerp = Quaternion.Slerp
		c.bezier = false
	private def fixChan(c as Channel_Color4):
		c.lerp = def(ref a as Color4, ref b as Color4, t as single) as Color4:
			return Color4.Gray
	private def fixChan(c as Channel_single):
		c.lerp = def(ref a as single, ref b as single, t as single) as single:
			return (1-t)*a + t*b
	
	
/*	private def fixChan2[of T(struct)](c as Channel[of T]) as void:
		if T == Quaternion:
			c.lerp = Quaternion.Slerp
			c.bezier = false
		elif T == Vector2:
			c.lerp = Vector2.Lerp
		elif T == Vector3:
			c.lerp = Vector3.Lerp
		elif T == Vector4:
			c.lerp = Vector4.Lerp
		elif T == Color4:
			c.lerp = def(a as Color4, b as Color4, t as single) as Color4:
				return Color4.Gray
		elif T == single:
			c.lerp = def(a as single, b as single, t as single) as single:
				return (1-t)*a + t*b
*/		

	#---	Read Abstract Channel (rac) constructor	---#
	
	# bypassing BOO-854
	[ext.spec.ForkMethodEx(Channel, (single,Vector2,Vector3,Vector4,Quaternion,Color4))]
	[ext.RemoveSource()]
	public def rac[of T(struct)](fread as callable(Reader) as T, fup as callable(IPlayer,T,byte)) as callable(Reader) as IChannel:
		return do(r as Reader):
			ind = r.getByte() # element index
			num = cast(int, r.bin.ReadUInt16() )
			chan = Channel[of T](num,ind,fup)
			fixChan(chan)
			chan.extrapolate = r.getByte()>0
			for i in range(num):
				chan.kar[i] = Key[of T]( t:r.getReal(),
					co:fread(r), h1:fread(r), h2:fread(r) )
			return chan
	
	#---	Unknown channel read	---#
	protected def readNullChannel() as IChannel:
		return null
	protected def readDefaultChannel(size as byte) as callable(Reader) as IChannel:
		if size == 1:	return rac( getReal, null )
		elif size == 2:	return rac( getVec2, null )
		elif size == 3:	return rac( getVector, null )
		elif size == 4:	return rac( getVec4, null )
		else: return readNullChannel
	
	#---	Parse curve	---#
	public def p_curve(r as Reader) as bool:
		rec	= r.geData[of Record]()
		return false	if not rec
		data_path = r.getString()
		siz = r.getByte()	# element size in floats
		fun as callable(Reader) as IChannel
		if not anid.TryGetValue(data_path,fun):
			badCurves[data_path] = siz
			fun = readDefaultChannel(siz)
		chan = fun(r)
		return false	if not chan
		chan.Tag = data_path
		rec.channels.Add(chan)
		return true
