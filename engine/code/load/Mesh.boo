namespace kri.load

import OpenTK
import OpenTK.Graphics.OpenGL

public class ExMesh( kri.IExtension ):
	def kri.IExtension.attach(nt as Native) as void:
		# mesh
		nt.readers['mesh']		= p_mesh
		nt.readers['v_pos']		= pv_pos
		nt.readers['v_quat']	= pv_quat
		nt.readers['v_uv']		= pv_uv
		nt.readers['v_color']	= pv_color
		nt.readers['v_ind']		= pv_ind
	
	public static def GetArray[of T(struct)](num as uint, fun as callable) as (T):
		ar = array[of T](num)
		for i in range( ar.Length ):
			ar[i] = fun()
		return ar
	public static def LoadArray[of T(struct)](r as Reader, multi as uint,
			ref ai as kri.vb.Info, fun as callable) as bool:
		m = r.geData[of kri.Mesh]()
		return false	if not m
		ar = GetArray[of T]( multi * m.nVert, fun )
		v = kri.vb.Attrib()
		v.init(ar,false)
		v.Semant.Add(ai)
		m.vbo.Add(v)
		return true

	
	#---	Parse mesh	---#
	public def p_mesh(r as Reader) as bool:
		m = kri.Mesh( BeginMode.Triangles )
		r.puData(m)
		m.nVert = r.bin.ReadInt16()
		return true
	
	#---	Parse mesh vertices (w = handness)	---#
	public def pv_pos(r as Reader) as bool:
		ai = kri.vb.Info(
			slot: kri.Ant.Inst.attribs.vertex, size:4,
			type: VertexAttribPointerType.Float,
			integer:false,	name:'vertex' )
		return LoadArray[of Vector4]( r,1,ai, r.getVec4 )
	
	#---	Parse mesh quaternions 	---#
	public def pv_quat(r as Reader) as bool:
		ai = kri.vb.Info(
			slot: kri.Ant.Inst.attribs.quat, size:4,
			type: VertexAttribPointerType.Float,
			integer:false,	name:'quat' )
		return LoadArray[of Quaternion]( r,1,ai, r.getQuat )
	
	#---	Parse mesh texture coordinates (UV)	---#
	public def pv_uv(r as Reader) as bool:
		m = r.geData[of kri.Mesh]()
		return false	if not m
		slot = System.Array.FindIndex( kri.Ant.Inst.attribs.tex ) do(i as int):
			return m.find(i) == null
		assert slot>=0
		r.getString()	# layer name, not used
		ai = kri.vb.Info(
			slot:kri.Ant.Inst.attribs.tex[slot], size:2,
			type:VertexAttribPointerType.Float,
			integer:false,	name:'tex'+slot )
		return LoadArray[of Vector2]( r,1,ai, r.getVec2 )
	
	#---	Parse mesh vertex colors	---#
	public def pv_color(r as Reader) as bool:
		m = r.geData[of kri.Mesh]()
		return false	if not m
		slot = System.Array.FindIndex( kri.Ant.Inst.attribs.color ) do(i as int):
			return m.find(i) == null
		assert slot>=0
		r.getString()	# layer name, not used
		ai = kri.vb.Info(
			slot:kri.Ant.Inst.attribs.color[slot], size:3,
			type:VertexAttribPointerType.UnsignedByte,
			integer:false,	name:'color')
		return LoadArray[of ColorRaw]( r,1,ai, r.getColorRaw )
	
	#---	Parse mesh indexes	---#
	public def pv_ind(r as Reader) as bool:
		m = r.geData[of kri.Mesh]()
		return false	if not m
		m.nPoly = r.bin.ReadUInt16()
		if m.nPoly:	# indexes
			af = GetArray[of ushort]( m.nPoly*3, r.bin.ReadUInt16 )
			m.ind = kri.vb.Index()
			m.ind.init(af,false)
		else: m.nPoly /= 3
		return true
