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
	public final con	= Context()
	public final dict	= Dictionary[of string,callable]()	# should be "callable() as bool"
	public final skipt	= Dictionary[of string,uint]()
	private final rep	= []
	private br	as IO.BinaryReader	= null
	private at	as Atom	= null
	private final nodeResolve	= Dictionary[of string,callable(kri.Node)]()
	
	public def constructor(*exclude as (string)):
		fillAniDict()
		fillMapinDict()
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
		dict['m_diff']	= pm_diff
		dict['m_spec']	= pm_spec
		dict['unit']	= pm_unit
		dict['tex']		= pm_tex
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
		dict['p_dist']	= pp_dist
		dict['p_life']	= pp_life
		dict['p_vel']	= pp_vel
		dict['p_rot']	= pp_rot
		dict['p_force']	= pp_force
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
			name = getString(8)
			size = br.ReadUInt32()
			size += bs.Position
			assert size <= bs.Length
			#p as callable() as bool = null
			p as callable = null
			if dict.TryGetValue(name,p) and p():
				assert bs.Position == size
			else:
				skipt[name] = size
				bs.Seek(size, IO.SeekOrigin.Begin)
		br.Close()
		for m in at.mats.Values:	m.link()
		for nr in nodeResolve:
			nr.Value( at.nodes[nr.Key] )
		nodeResolve.Clear()
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
		return getVector().LengthSquared / 3f
	protected def getColor() as Color4:
		return Color4( getReal(), getReal(), getReal(), 1f )
	protected def getColorByte() as Color4:
		c = br.ReadBytes(3)	#rbg
		a as byte = 0xFF
		return Color4(c[0],c[2],c[1],a)
	protected def getString(size as byte) as string:
		return string( br.ReadChars(size) ).TrimEnd( char(0) )
	protected def getString() as string:
		return getString( br.ReadByte() )
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
		return kri.Spatial.EulerQuat( getVector() )
	protected def getSpatial() as kri.Spatial:
		return kri.Spatial( pos:getVector(), scale:getReal(), rot:getQuat() )
	
	public def p_sign() as bool:
		ver = br.ReadByte()
		assert ver == 3 and not rep.Count
		return true
