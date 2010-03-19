namespace kri.load

import OpenTK

public partial class Native:
	public def getCurve[of T(struct)](fun as callable) as Stack[of kri.ani.data.Key[of T]]:
		num = br.ReadUInt16()
		#br.ReadByte()	# extrapolate
		ar = Stack[of kri.ani.data.Key[of T]](num+1)
		ar.Push( kri.ani.data.Key[of T](t:-1.0f) )
		for k in range(num):
			ar.Push( kri.ani.data.Key[of T]( t:getReal(), co:fun(br) ))
		return ar

	#---	Parse skeleton	---#
	public def p_skel() as bool:
		node = geData[of kri.Node]()
		return false	if not node
		nbones = br.ReadByte()
		s = kri.Skeleton( node,nbones )
		puData(s)
		# read nodes
		par = array[of byte](nbones)
		for i in range(nbones):
			name = getString(STR_LEN)
			par[i] = br.ReadByte()
			s.bones[i] = kri.NodeBone(name, getSpatial())
		for i in range(nbones):
			s.bones[i].Parent = (s.bones[par[i]-1] if par[i] else node)
		s.bakePoseData(node)
		return true
	
	#---	Parse skeletal action	---#
	public def pn_act() as bool:
		skel = geData[of kri.Skeleton]()
		return false	if not skel
		name = getString(STR_LEN)
		rec = kri.ani.data.Record( name, getReal() )
		skel.anims.Add(rec)
		puData(rec)
		#node = geData[of kri.Node]()
		#return false	if not node
		#ad = kri.AniData( getString(STR_LEN), getReal() )
		#node.anims.Add(ad)
		#puData(ad)
		return true

	#---	Parse action channel	---#
	public def pa_bone() as bool:
		rec	= geData[of kri.ani.data.Record]()
		return false	if not rec
		#ad	= geData[of kri.AniData]()
		#return false	if not ad
		bid = br.ReadByte()
		return false	if not bid
		#stack = Stack[of kri.BoneRecord]()
		stack = Stack[of kri.ani.data.Key[of kri.Spatial]]()
		pos = getCurve[of Vector3](getVector)
		rot = getCurve[of Quaternion](getQuat)
		sca = getCurve[of single](getReal)
		# merge IPOs
		#bone as kri.BoneRecord
		bone as kri.ani.data.Key[of kri.Spatial]
		while true:
			bone.co = kri.Spatial.Identity
			t0,t1,t2 = (pos.Peek().t),(rot.Peek().t),(sca.Peek().t)
			bone.t = System.Math.Max( System.Math.Max(t0,t1), t2 )
			break	if bone.t < 0.0
			t = bone.t - System.Single.Epsilon
			if t0 >= t:	bone.co.pos	= pos.Pop().co
			if t1 >= t: bone.co.rot	= rot.Pop().co
			if t2 >= t: bone.co.scale	= sca.Pop().co
			stack.Push(bone)
		# fill a bone channel
		#chan = kri.BoneChannel(bid, stack.Count)
		chan = kri.BoneChannel2(bid-1, stack.Count)
		for k in range(stack.Count):
			chan.kar[k] = stack.Pop()
		#ad.channels.Add(chan)
		rec.channels.Add(chan)
		return true
