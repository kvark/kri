namespace kri.load

import OpenTK
import kri.ani.data

public partial class Native:
	# fill action dictionary
	# should be callable(ref kri.Spatial,ref T) as void
	private def genBone[of T(struct)](fun as callable) as callable(byte) as callable:
		return do(i as byte):
			return do(pl as IPlayer, v as T):
				assert i
				bar = (pl as kri.Skeleton).bones
				fun( bar[i-1].pose, v )	if i <= bar.Length

	public def fillAdic() as void:
		# skeleton bone
		adic['s.location']				= genBone[of Vector3]()		do(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.pos = v
		adic['s.rotation_quaternion']	= genBone[of Quaternion]()	do(ref sp as kri.Spatial, ref v as Quaternion) as void:
			sp.rot = v
		adic['s.scale']					= genBone[of Vector3]()		do(ref sp as kri.Spatial, ref v as Vector3) as void:
			sp.scale = v.LengthFast


	public def getQuat2() as Quaternion:
		return Quaternion( W:getReal(), Xyz:getVector() )
	
	#---	Parse abstract action	---#
	[ext.spec.NameMethod( kri.Skeleton )]
	public def px_act[of T(Player)]() as bool:
		player = geData[of T]()
		return false	if not player
		name = getString(STR_LEN)
		rec = Record( name, getReal() )
		player.anims.Add(rec)
		puData(rec)
		return true
	
	[ext.spec.ForkMethod(true, getX, getVector, Vector3)]
	[ext.spec.ForkMethod(true, getX, getQuat2, Quaternion)]
	[ext.spec.ForkMethod(true, getX, getColor, Color4)]
	[ext.RemoveSource()]
	public def px_curve[of T(struct)]() as bool:
		def getX() as T:
			x as T
			return x
		ind = br.ReadByte() # element index
		siz = br.ReadByte()	# element size in floats
		assert siz*4 == kri.Sizer[of T].Value
		rec	= geData[of Record]()
		return false	if not rec
		fun = adic[ getString(STR_LEN) ](ind)
		num = br.ReadUInt16()
		chan = Channel[of T](num,fun)
		rec.channels.Add(chan)
		chan.extrapolate = br.ReadByte()>0
		for i in range(num):
			chan.kar[i] = Key[of T]( t:getReal(),
				co:getX(), h1:getX(), h2:getX() )
		return true
