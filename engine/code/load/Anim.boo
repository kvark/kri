namespace kri.load

import OpenTK
import kri.ani.data

public partial class Native:
	public final anid		= Dictionary[of string,callable() as IChannel]()
	public final badCurves	= Dictionary[of string,byte]()

	# should be callable(ref kri.Spatial,ref T) as void (waiting for BOO-854)
	# generates invalid binary format if using generics, bypassing with extenions
	[ext.spec.Method(Vector3,Quaternion,single)]
	[ext.RemoveSource()]
	private def genBone		[of T(struct)](fun as callable(ref kri.Spatial, ref T)):
		return do(pl as IPlayer, v as T, i as byte):
			bar = (pl as kri.Skeleton).bones
			return if not i or i>bar.Length
			fun( bar[i-1].pose, v )
	
	[ext.spec.Method(Vector3,Quaternion,single)]
	[ext.RemoveSource()]
	private def genSpatial	[of T(struct)](fun as callable(ref kri.Spatial, ref T)):
		return do(pl as IPlayer, v as T, i as byte):
			n = pl as kri.Node
			sp = n.Local
			fun(sp,v)
			n.Local = sp
	
	private def racMatColor(mid as int):
		return rac(getColor) do(pl as IPlayer, v as Color4, i as byte):
			((pl as kri.Material).meta[mid] as kri.IColored).Color = v
	private def racProject(fun as callable(kri.Projector,single)):
		return rac(getReal) do(pl as IPlayer, v as single, i as byte):
			assert not i
			fun(pl as kri.Projector, v)

	# fill action dictionary
	public def fillAdic() as void:
		# spatial sub-trans
		def fun_pos(ref sp as kri.Spatial, ref v as Vector3):
			sp.pos = v
		def fun_rot(ref sp as kri.Spatial, ref v as Quaternion):
			sp.rot = v
		def fun_sca(ref sp as kri.Spatial, ref v as single):
			sp.scale = v
		# projector sub-trans
		def fun_prin(pr as kri.Projector, v as single):
			pr.rangeIn = v
		def fun_prout(pr as kri.Projector, v as single):
			pr.rangeOut = v
		# skeleton bone
		anid['s.location']				= rac(getVector,	genBone(fun_pos) )
		anid['s.rotation_quaternion']	= rac(getQuat,		genBone(fun_rot) )
		anid['s.scale']					= rac(getScale,		genBone(fun_sca) )
		# node
		anid['n.location']			= rac(getVector,	genSpatial(fun_pos) )
		anid['n.rotation_euler']	= rac(getQuatEuler,	genSpatial(fun_rot) )
		anid['n.scale']				= rac(getScale,		genSpatial(fun_sca) )
		# material
		anid['m.diffuse_color']		= racMatColor( con.ms.diffuse )
		anid['m.specular_color']	= racMatColor( con.ms.specular )
		# light
		anid['l.energy']	= rac(getReal,	{pl,v,i| (pl as kri.Light).energy = v })
		anid['l.color']		= rac(getColor,	{pl,v,i| (pl as kri.IColored).Color = v })
		anid['l.clip_start']	= racProject(fun_prin)
		anid['l.clip_end']		= racProject(fun_prout)
		# camera
		anid['c.angle']		= rac(getReal) do(pl as IPlayer, v as single, i as byte):
			(pl as kri.Camera).fov = v*0.5f
		anid['c.clip_start']	= racProject(fun_prin)
		anid['c.clip_end']		= racProject(fun_prout)


	#---	Parse action	---#
	public def p_action() as bool:
		player = geData[of Player]()
		return false	if not player
		name = getString(STR_LEN)
		rec = Record( name, getReal() )
		player.anims.Add(rec)
		puData(rec)
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
	
	#---	Read Abstract Channel (rac) constructor	---#
	# bypassing BOO-854
	[ext.spec.ForkMethodEx(Channel, single)]
	[ext.spec.ForkMethodEx(Channel, Vector2)]
	[ext.spec.ForkMethodEx(Channel, Vector3)]
	[ext.spec.ForkMethodEx(Channel, Vector4)]
	[ext.spec.ForkMethodEx(Channel, Quaternion)]
	[ext.spec.ForkMethodEx(Channel, Color4)]
	[ext.RemoveSource()]
	public def rac[of T(struct)](fread as callable() as T, fup as callable(IPlayer,T,byte)) as callable() as IChannel:
		return do():
			ind = br.ReadByte() # element index
			num = br.ReadUInt16()
			chan = Channel[of T](num,ind,fup)
			fixChan(chan)
			chan.extrapolate = br.ReadByte()>0
			for i in range(num):
				chan.kar[i] = Key[of T]( t:getReal(),
					co:fread(), h1:fread(), h2:fread() )
			return chan
	
	#---	Unknown channel read	---#
	protected def readNullChannel() as IChannel:
		return null
	protected def readDefaultChannel(size as byte) as callable() as IChannel:
		if size == 1:	return rac( getReal, null )
		elif size == 2:	return rac( getVec2, null )
		elif size == 3:	return rac( getVector, null )
		elif size == 4:	return rac( getVec4, null )
		else: return readNullChannel
	
	#---	Parse curve	---#
	public def p_curve() as bool:
		rec	= geData[of Record]()
		return false	if not rec
		data_path = getString(STR_LEN)
		siz = br.ReadByte()	# element size in floats
		fun as callable() as IChannel
		if not anid.TryGetValue(data_path,fun):
			badCurves.Add(data_path,siz)
			fun = readDefaultChannel(siz)
		chan = fun()
		return false	if not chan
		rec.channels.Add(chan)
		return true
