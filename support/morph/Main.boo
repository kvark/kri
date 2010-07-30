namespace support.morph

import System
import OpenTK


#----------------------------------------
#	Shape Key, stored as an entity tag

public class Tag( kri.ITag ):
	public final name	as string
	public final data	= kri.vb.Attrib()
	public relative	as Tag		= null
	[Getter(Dirty)]
	private dirty	as bool		= false
	private val		as single	= 1f
	public Value	as single:
		get: return val
		set: dirty=true; val=value
	public def constructor(s as string):
		name = s


#----------------------------------------
#	Engine extension - loader

public class Extra( kri.IExtension ):
	private def racShape(pl as kri.ani.data.IPlayer, v as single, i as byte):
		keys = (pl as kri.Entity).enuTags[of Tag]()
		keys[i-1].Value = v
	
	public def attach(nt as kri.load.Native) as void:	#imp: kri.IExtension
		nt.readers['v_shape']	= pv_shape
		# shape key
		anil = kri.Ant.Inst.loaders.animations
		anil.anid['v.value']	= kri.load.ExAnim.Rac( kri.load.ExAnim.getReal, racShape)
	
	#---	Parse shape key		---#
	public def pv_shape(r as kri.load.Reader) as bool:
		e = r.geData[of kri.Entity]()
		return false	if not e or not e.mesh
		tag = Tag( r.getString() )
		r.getByte()	# relative ID, not used
		tag.Value = r.getReal()
		ar = kri.load.ExMesh.GetArray[of Vector3]( e.mesh.nVert, r.getVector )
		tag.data.init(ar,false)
		kri.Help.enrich( tag.data, 3, kri.Ant.Inst.attribs.vertex )
		e.tags.Add(tag)
		return true
