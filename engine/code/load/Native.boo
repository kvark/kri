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
		dict['node']	= p_node
		dict['entity']	= p_entity
		dict['skel']	= p_skel
		dict['cam']		= p_cam
		dict['lamp']	= p_lamp
		# material
		dict['mat']		= p_mat
		dict['tex']		= p_tex
		# animations
		dict['action']	= p_action
		dict['curve']	= p_curve
		# mesh
		dict['mesh']	= p_mesh
		dict['v_pos']	= pv_pos
		dict['v_quat']	= pv_quat
		dict['v_uv']	= pv_uv
		dict['v_skin']	= pv_skin
		dict['v_ind']	= pv_ind
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
		#return rep.Find(predicate) as T
		for ob in rep:
			t = ob as T
			return t	if t
		return null as T
	protected def puData[of T](r as T) as void:
		#rep.RemoveAll(predicate)
		rep.Remove( geData[of T] )
		rep.Insert(0,r)
	
	protected def getReal() as single:
		return br.ReadSingle()
	protected def getScale() as single:
		return getVector().LengthFast
	protected def getColor() as Color4:
		return Color4( getReal(), getReal(), getReal(), 1f )
	protected def getString(n as int) as string:
		return string( br.ReadChars(n) ).TrimEnd( char(0) )
	protected def getVector() as Vector3:
		return Vector3( X:getReal(), Y:getReal(), Z:getReal() )
	protected def getVec2() as Vector2:
		return Vector2( X:getReal(), Y:getReal() )
	protected def getVec4() as Vector4:
		return Vector4( Xyz:getVector(), W:getReal() )
	protected def getQuat() as Quaternion:
		return Quaternion( Xyz:getVector(), W:getReal() )
	protected def getQuatRev() as Quaternion:
		return Quaternion( W:getReal(), Xyz:getVector() )
	protected def getQuatEuler() as Quaternion:
		getVector()
		return Quaternion.Identity
	protected def getSpatial() as kri.Spatial:
		return kri.Spatial( pos:getVector(), scale:getReal(), rot:getQuat() )
	
	public def p_sign() as bool:
		ver = br.ReadByte()
		assert ver == 3 and not rep.Count
		return true
