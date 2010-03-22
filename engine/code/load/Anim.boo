namespace kri.load

import OpenTK
import kri.ani.data

public partial class Native:
	public final adic	= Dictionary[of string,callable]()

	# should be callable(ref kri.Spatial,ref T) as void (waiting for BOO-854)
	# generates invalid binary format if using generics, bypassing with extenions
	[ext.spec.Method(Vector3,Quaternion)]
	[ext.RemoveSource()]
	private def genBone[of T(struct)](fun as callable(ref kri.Spatial, ref T)) as callable:
		return do(pl as IPlayer, v as T, i as byte):
			bar = (pl as kri.Skeleton).bones
			return if not i or i>bar.Length
			fun( bar[i-1].pose, v )
	
	[ext.spec.Method(Vector3,Quaternion)]
	[ext.RemoveSource()]
	private def genSpatial[of T(struct)](fun as callable(ref kri.Spatial, ref T)) as callable:
		return do(pl as IPlayer, v as T, i as byte):
			n = pl as kri.Node
			sp = n.Local
			fun(sp,v)
			n.Local = sp
	
	private def genMatColor(mid as int) as callable:
		return do(pl as IPlayer, v as Color4, i as byte):
			((pl as kri.Material).meta[mid] as kri.IColored).Color = v
	
	private def doNothing(pl as IPlayer, v as Color4, i as byte):
		pass
	private def doProjNear	(pl as IPlayer, v as single, i as byte):
		(pl as kri.Projector).rangeIn = v
	private def doProjFar	(pl as IPlayer, v as single, i as byte):
		(pl as kri.Projector).rangeOut = v
			

	# fill action dictionary
	public def fillAdic() as void:
		# spatial sub-trans
		def fun_pos(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.pos = v
		def fun_rot(ref sp as kri.Spatial, ref v as Quaternion) as void:
			sp.rot = v
		def fun_sca(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.scale = v.LengthFast
		# skeleton bone
		adic['s.location']				= genBone(fun_pos)
		adic['s.rotation_quaternion']	= genBone(fun_rot)
		adic['s.scale']					= genBone(fun_sca)
		# node
		adic['n.location']			= genSpatial(fun_pos)
		adic['n.rotation_euler']	= genSpatial(fun_rot)
		adic['n.scale']				= genSpatial(fun_sca)
		# material
		adic['t.diffuse_color']		= genMatColor( con.ms.diffuse )
		adic['t.specular_color']	= genMatColor( con.ms.specular )
		# light
		adic['l.energy']	= do(pl as IPlayer, v as single, i as byte):
			(pl as kri.Light).energy = v
		adic['l.color']		= do(pl as IPlayer, v as Color4, i as byte):
			(pl as kri.IColored).Color = v
		adic['l.clip_start'] = doProjNear
		adic['l.clip_end'] = doProjFar
		# camera
		adic['c.angle']		= do(pl as IPlayer, v as single, i as byte):
			(pl as kri.Camera).fov = v * 0.5f
		adic['c.clip_start'] = doProjNear
		adic['c.clip_end'] = doProjFar


	#---	Parse action	---#
	public def p_action() as bool:
		player = geData[of Player]()
		return false	if not player
		name = getString(STR_LEN)
		rec = Record( name, getReal() )
		player.anims.Add(rec)
		puData(rec)
		return true

	
	private def fixChan(c as Channel_Vector3):
		c.lerp = Vector3.Lerp
	private def fixChan(c as Channel_Quaternion):
		c.lerp = Quaternion.Slerp
		c.bezier = false
	private def fixChan(c as Channel_Color4):
		c.lerp = def(ref a as Color4, ref b as Color4, t as single) as Color4:
			return Color4.Gray
	private def fixChan(c as Channel_single):
		c.lerp = def(ref a as single, ref b as single, t as single) as single:
			return (1-t)*a + t*b
	
	private def readX(ref x as Vector3):
		x = getVector()
	private def readX(ref x as Quaternion):
		x.W = getReal()
		x.Xyz = getVector()
	private def readX(ref x as Color4):
		x = Color4( getReal(), getReal(), getReal(), 1f )
	private def readX(ref x as single):
		x = getReal()
	
	# bypassing BOO-854
	#[ext.spec.MethodSubClass(Channel, Vector3,Quaternion)]
	#[ext.spec.ForkMethod(getX, getVector, Vector3)]
	#[ext.spec.ForkMethod(getX, getQuat2, Quaternion)]
	#[ext.spec.ForkMethod(getX, getColor, Color4)
	#[ext.spec.Method( Vector3, Quaternion, Color4 )]
	[ext.spec.ForkMethodEx(Channel, Vector3)]
	[ext.spec.ForkMethodEx(Channel, Quaternion)]
	[ext.spec.ForkMethodEx(Channel, Color4)]
	[ext.spec.ForkMethodEx(Channel, single)]
	[ext.RemoveSource()]
	public def px_curve[of T(struct)]() as bool:
		#def getX() as T:
		#	x as T
		#	return x
		ind = br.ReadByte() # element index
		br.ReadByte()	# element size in floats
		#assert siz*4 == kri.Sizer[of T].Value
		rec	= geData[of Record]()
		return false	if not rec
		fun as callable = null
		data_path = getString(STR_LEN)
		if not adic.TryGetValue(data_path,fun):
			fun = doNothing
		num = br.ReadUInt16()
		chan = Channel[of T](num,ind,fun)
		fixChan(chan)
		rec.channels.Add(chan)
		chan.extrapolate = br.ReadByte()>0
		for i in range(num):
			t = Key[of T]( t:getReal() )
			readX( t.co )
			readX( t.h1 )
			readX( t.h2 )
			chan.kar[i] = t
			#chan.kar[i] = Key[of T]( t:getReal(),
			#	co:getX(), h1:getX(), h2:getX() )
		return true
