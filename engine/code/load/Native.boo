namespace kri.load

import System
import System.Collections.Generic
import OpenTK

#------		LOAD ATOM		------#

public class Atom:
	public final scene		as kri.Scene
	public final nodes		= Dictionary[of string,kri.Node]()
	public final mats		= Dictionary[of string,kri.Material]()
	
	public def constructor(name as string):
		scene = kri.Scene(name)
		nodes[''] = null
	

#------		CHUNK LOADER		------#

public partial class Native:
	public static final NAME_LEN	= 8
	public static final STR_LEN		= 24
	public static final PATH_LEN	= 64
	public final con	= Context()
	public final dict	= Dictionary[of string, callable]()	# should be "callable() as bool"
	private final rep	= []
	private br	as IO.BinaryReader	= null
	private at	as Atom	= null
	
	public def constructor(*exclude as (string)):
		fillAdic()
		# Fill chunk dictionary
		dict['kri']		= p_sign
		# objects
		dict['entity']	= p_entity
		dict['node']	= p_node
		dict['cam']		= p_cam
		dict['lamp']	= p_lamp
		# material
		dict['mat']		= p_mat
		dict['tex']		= p_tex
		# animations
		dict['av_seq']	= px_curve_Vector3
		dict['aq_seq']	= px_curve_Quaternion
		dict['ac_seq']	= px_curve_Color4
		dict['ae_seq']	= px_curve_Vector3
		# mesh
		dict['mesh']	= p_mesh
		dict['v_pos']	= pv_pos
		dict['v_quat']	= pv_quat
		dict['v_uv']	= pv_uv
		dict['v_skin']	= pv_skin
		dict['v_ind']	= pv_ind
		# skeleton
		dict['skel']	= p_skel
		dict['s_act']	= px_act_Skeleton
		dict['n_act']	= px_act_Node
		dict['m_act']	= px_act_Material
		# particles
		dict['part']	= p_part
		# physics
		#dict['body']	= Read.body
		for ex in exclude:
			assert ex in dict
			dict.Remove(ex)
	
	public def read(path as string) as Atom:
		kri.res.check(path)
		rep.Clear()
		br = IO.BinaryReader( IO.File.OpenRead(path) )
		at = Atom(path)
		bs = br.BaseStream
		while bs.Position != bs.Length:
			name = getString(NAME_LEN)
			size = br.ReadUInt32()
			size += bs.Position
			assert size <= bs.Length
			#p as callable() as bool = null
			p as callable = null
			if dict.TryGetValue(name,p) and p():
				assert bs.Position == size
			else: bs.Seek(size, IO.SeekOrigin.Begin)
		br.Close()
		for m in at.mats.Values:
			m.link()
		return at
	
	protected def geData[of T]() as T:
		#return rep.Find( {t| return t isa T} ) as T
		for ob in rep:
			t = ob as T
			return t	if t
		return null as T
	protected def puData[of T](r as T) as void:
		#rep.RemoveAll({t| t isa T})
		rep.Remove( geData[of T]() )
		rep.Add(r)
	
	protected def getReal() as single:
		return br.ReadSingle()
	protected def getString(n as int) as string:
		return string( br.ReadChars(n) ).TrimEnd( char(0) )
	protected def getVector() as Vector3:
		return Vector3( X:getReal(), Y:getReal(), Z:getReal() )
	protected def getQuat() as Quaternion:
		return Quaternion( Xyz:getVector(), W:getReal() )
	protected def getSpatial() as kri.Spatial:
		return kri.Spatial( pos:getVector(), scale:getReal(), rot:getQuat() )
	protected def getQuatRev() as Quaternion:
		return Quaternion( W:getReal(), Xyz:getVector() )
	protected def getQuatEuler() as Quaternion:
		getVector()
		return Quaternion.Identity
	
	public def p_sign() as bool:
		ver = br.ReadByte()
		assert ver == 3 and not rep.Count
		return true
