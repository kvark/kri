namespace kri.load

import OpenTK
import OpenTK.Graphics.OpenGL

public partial class Native:

	protected def getArray[of T(struct)](num as uint, fun as callable) as (T):
		ar = array[of T](num)
		for i in range( ar.Length ):
			ar[i] = fun()
		return ar
	protected def loadArray[of T(struct)](multi as uint,
			ref ai as kri.vb.Info, fun as callable) as bool:
		m = geData[of kri.Mesh]()
		return false	if not m
		ar = getArray[of T]( multi * m.nVert, fun )
		v = kri.vb.Attrib()
		v.init(ar,false)
		v.Semant.Add(ai)
		m.vbo.Add(v)
		return true

	#---	Parse mesh	---#
	public def p_mesh() as bool:
		m = kri.Mesh( BeginMode.Triangles )
		puData(m)
		m.nVert = br.ReadInt16()
		return true
	
	#---	Parse shape key		---#
	public def pv_shape() as bool:
		e = geData[of kri.Entity]()
		return false	if not e or not e.mesh
		tag = kri.kit.morph.Key( getString() )
		br.ReadByte()	# relative ID, not used
		tag.Value = getReal()
		ar = getArray[of Vector3]( e.mesh.nVert, getVector )
		tag.data.init(ar,false)
		kri.Help.enrich( tag.data, 3, kri.Ant.Inst.attribs.vertex )
		e.tags.Add(tag)
		return true
	
	#---	Parse mesh vertices (w = handness)	---#
	public def pv_pos() as bool:
		ai = kri.vb.Info(
			slot: kri.Ant.Inst.attribs.vertex, size:4,
			type: VertexAttribPointerType.Float,
			integer:false )
		return loadArray[of Vector4](1,ai,getVec4)
	
	#---	Parse mesh quaternions 	---#
	public def pv_quat() as bool:
		ai = kri.vb.Info(
			slot: kri.Ant.Inst.attribs.quat, size:4,
			type: VertexAttribPointerType.Float,
			integer:false )
		return loadArray[of Quaternion](1,ai,getQuat)
	
	#---	Parse mesh texture coordinates (UV)	---#
	public def pv_uv() as bool:
		m = geData[of kri.Mesh]()
		return false	if not m
		slot = System.Array.FindIndex( kri.Ant.Inst.attribs.tex ) do(i as int):
			return m.find(i) == null
		assert slot>=0
		getString()	# layer name, not used
		ai = kri.vb.Info(
			slot:kri.Ant.Inst.attribs.tex[slot], size:2,
			type:VertexAttribPointerType.Float,
			integer:false )
		return loadArray[of Vector2](1,ai,getVec2)
	
	#---	Parse mesh vertex colors	---#
	public def pv_color() as bool:
		m = geData[of kri.Mesh]()
		return false	if not m
		slot = System.Array.FindIndex( kri.Ant.Inst.attribs.color ) do(i as int):
			return m.find(i) == null
		assert slot>=0
		getString()	# layer name, not used
		ai = kri.vb.Info(
			slot:kri.Ant.Inst.attribs.color[slot], size:3,
			type:VertexAttribPointerType.UnsignedByte,
			integer:false )
		return loadArray[of ColorRaw](1,ai,getColorRaw)
	
	#---	Parse mesh armature link with bone weights	---#
	public def pv_skin() as bool:
		ai = kri.vb.Info(
			slot: kri.Ant.Inst.attribs.skin, size:4,
			type: VertexAttribPointerType.UnsignedShort,
			integer:true )
		rez = loadArray[of ushort](4,ai, {return br.ReadUInt16()})
		return false	if not rez
		# link to the Armature
		kri.kit.skin.Tag.prepare(
			geData[of kri.Entity](),
			geData[of kri.Skeleton]() )
		return true
	
	#---	Parse mesh indexes	---#
	public def pv_ind() as bool:
		m = geData[of kri.Mesh]()
		return false	if not m
		m.nPoly = br.ReadUInt16()
		if m.nPoly:	# indexes
			af = getArray[of ushort]( m.nPoly*3, br.ReadUInt16 )
			m.ind = kri.vb.Index()
			m.ind.init(af,false)
		else: m.nPoly /= 3
		return true
