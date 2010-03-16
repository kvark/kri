namespace kri.load

import OpenTK

public partial class Native:
	protected struct IpoData[of T(struct)]:
		public t as single
		public d as T
	protected def getIpo[of T(struct)](fun as callable) as Stack[of IpoData[of T]]:
		num = br.ReadUInt16()
		ar = Stack[of IpoData[of T]](num+1)
		ar.Push( IpoData[of T](t:-1.0f) )
		for k in range(num):
			ar.Push( IpoData[of T]( t:getReal(), d:fun(br) ))
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
		node = geData[of kri.Node]()
		return false	if not node
		ad = kri.AniData( getString(STR_LEN), getReal() )
		node.anims.Add(ad)
		puData(ad)
		return true

	#---	Parse action channel	---#
	public def pa_bone() as bool:
		ad	= geData[of kri.AniData]()
		return false	if not ad
		bid = br.ReadByte()
		stack = Stack[of kri.BoneRecord]()
		pos = getIpo[of Vector3](getVector)
		rot = getIpo[of Quaternion](getQuat)
		sca = getIpo[of single](getReal)
		# merge IPOs
		bone as kri.BoneRecord
		while true:
			bone.d = kri.Spatial.Identity
			t0,t1,t2 = (pos.Peek().t),(rot.Peek().t),(sca.Peek().t)
			bone.t = System.Math.Max( System.Math.Max(t0,t1), t2 )
			break	if bone.t < 0.0
			t = bone.t - System.Single.Epsilon
			if t0 >= t:	bone.d.pos	= pos.Pop().d
			if t1 >= t: bone.d.rot	= rot.Pop().d
			if t2 >= t: bone.d.scale	= sca.Pop().d
			stack.Push(bone)
		# fill a bone channel
		chan = kri.BoneChannel(bid, stack.Count)
		for k in range(stack.Count):
			chan.c[k] = stack.Pop()
		ad.channels.Add(chan)
		return true
