namespace support.skin

import OpenTK.Graphics.OpenGL


#----------------------------------------
#	Skeleton binding, stored as an entity tag

public class Tag( kri.ITag ):
	public skel		as kri.Skeleton	= null
	private state	as int	 = 0
	public Sync as bool:
		get: return state == skel.State
		set: state = skel.State - (0 if value else 1)
	public static def getAnim(e as kri.Entity, str as string) as kri.ani.data.Anim:
		return e.seTag[of Tag]().skel.play(str)


#----------------------------------------
#	Engine extension - loader

public class Extra( kri.IExtension ):
	public final attrib	= kri.Ant.Inst.slotAttributes.create('skin')
	
	def kri.IExtension.attach(nt as kri.load.Native) as void:
		nt.readers['v_skin']	= pv_skin
	
	#---	Parse mesh armature link with bone weights	---#
	public def pv_skin(r as kri.load.Reader) as bool:
		ai = kri.vb.Info( slot:attrib, size:4,
			type:VertexAttribPointerType.UnsignedShort,
			integer:true, name:'skin' )
		rez = kri.load.ExMesh.LoadArray[of ushort]( r,4,ai, {return r.bin.ReadUInt16()})
		return false	if not rez
		# link to the Armature
		prepare(
			r.geData[of kri.Entity](),
			r.geData[of kri.Skeleton]() )
		return true

	public def prepare(e as kri.Entity, s as kri.Skeleton) as bool:
		a = kri.Ant.Inst.attribs
		cond = e and s and not e.seTag[of Tag]() and e.mesh.find(attrib)
		return false	if not cond
		for at in (a.vertex, a.quat):
			continue	if e.store.find(at)
			v = e.mesh.find(at)
			return false	if not v
			ai = v.Semant[0]
			v2 = kri.vb.Attrib()
			v2.Semant.Add(ai)
			v2.init( e.mesh.nVert * ai.fullSize() )
			e.store.vbo.Add(v2)
		e.tags.Add( Tag(skel:s) )
		return true
