namespace kri.load

import OpenTK
import kri.ani.data

public partial class Native:
	public final adic	= Dictionary[of string, callable(byte) as callable]()

	# should be callable(ref kri.Spatial,ref T) as void (waiting for BOO-854)
	# generates invalid binary format if using generics, bypassing with extenions
	[ext.spec.Method(Vector3,Quaternion)]
	[ext.RemoveSource()]
	private def genBone[of T(struct)](fun as callable(ref kri.Spatial, ref T)) as callable(byte) as callable:
		return do(i as byte):
			return do(pl as IPlayer, v as T):
				assert i
				bar = (pl as kri.Skeleton).bones
				fun( bar[i-1].pose, v )	if i <= bar.Length

	# fill action dictionary
	public def fillAdic() as void:
		# skeleton bone
		adic['s.location']				= genBone()	do(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.pos = v
		adic['s.rotation_quaternion']	= genBone()	do(ref sp as kri.Spatial, ref v as Quaternion) as void:
			sp.rot = v
		adic['s.scale']					= genBone()	do(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.scale = v.LengthFast


	public def getQuat2() as Quaternion:
		return Quaternion( W:getReal(), Xyz:getVector() )
	
	#---	Parse abstract action	---#
	[ext.spec.Method( kri.Skeleton )]
	public def px_act[of T(Player)]() as bool:
		player = geData[of T]()
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
	
	private def readX(ref x as Vector3):
		x = getVector()
	private def readX(ref x as Quaternion):
		x = getQuat2()
	private def readX(ref x as Color4):
		x = getColor()
	
	# bypassing BOO-854
	#[ext.spec.MethodSubClass(Channel, Vector3,Quaternion)]
	#[ext.spec.ForkMethod(getX, getVector, Vector3)]
	#[ext.spec.ForkMethod(getX, getQuat2, Quaternion)]
	#[ext.spec.ForkMethod(getX, getColor, Color4)
	#[ext.spec.Method( Vector3, Quaternion, Color4 )]
	[ext.spec.ForkMethodEx(Channel, Vector3)]
	[ext.spec.ForkMethodEx(Channel, Quaternion)]
	[ext.spec.ForkMethodEx(Channel, Color4)]
	[ext.RemoveSource()]
	public def px_curve[of T(struct)]() as bool:
		#def getX() as T:
		#	x as T
		#	return x
		ind = br.ReadByte() # element index
		siz = br.ReadByte()	# element size in floats
		assert siz*4 == kri.Sizer[of T].Value
		rec	= geData[of Record]()
		return false	if not rec
		fun = adic[ getString(STR_LEN) ](ind)
		num = br.ReadUInt16()
		chan = Channel[of T](num,fun)
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
