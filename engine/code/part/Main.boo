namespace kri.part

import System
import OpenTK.Graphics.OpenGL


public class DataHolder:
	public data		as kri.vb.Attrib	= null
	public va		= kri.vb.Array()
	public def init(sem as kri.vb.attr.Info*, num as uint) as void:
		if data:	data.semantics.Clear()
		else:		data = kri.vb.Attrib()
		data.semantics.AddRange(sem)
		va.bind()
		data.initAll( num )


#---------------------------------------#
#	PARTICLE EMITTER 					#
#---------------------------------------#

public class Emitter(DataHolder):
	public visible	as bool		= true
	public onUpdate	as callable(kri.Entity) as bool	= null
	public onDraw	as callable() as bool	= null
	public obj		as kri.Entity	= null
	public sa		as kri.shade.Smart	= null
	public halo		as kri.meta.Halo	= null
	public final man	as Manager
	public final name	as string

	public def constructor(pm as Manager, str as string):
		man,name = pm,str
	public def constructor(pe as Emitter):
		visible	= pe.visible
		onDraw	= pe.onDraw
		obj		= pe.obj
		sa		= pe.sa
		halo	= pe.halo
		man		= pe.man
		name	= pe.name
	public def prepare() as bool:
		return (not onUpdate) or onUpdate(obj)
		
	public def draw() as void:
		assert sa
		return	if onDraw and not onDraw()
		va.bind()
		sa.use()
		GL.DrawArrays( BeginMode.Points, 0, man.total )


#---------------------------------------#
#	PARTICLE CREATION CONTEXT			#
#---------------------------------------#

public class Context:
	public final	at_sys	= kri.Ant.Inst.slotParticles.getForced('sys')
	# root shaders
	public final	v_init	= kri.shade.Object('/part/init_v')
	public final	sh_draw	= kri.shade.Object('/part/draw/main_v')
	public final	sh_root	= kri.shade.Object('/part/root_v')
	public final	sh_tool	= kri.shade.Object('/part/tool_v')
	# born shaders
	public final	sh_born_instant	= kri.shade.Object('/part/born/instant_v')
	public final	sh_born_static	= kri.shade.Object('/part/born/static_v')
	public final	sh_born_time	= kri.shade.Object('/part/born/time_v')
	# emit surface shaders
	public final	sh_surf_node	= kri.shade.Object('/part/surf/node_v')
	public final	sh_surf_vertex	= kri.shade.Object('/part/surf/vertex_v')
	public final	sh_surf_face	= kri.shade.Object('/part/surf/face_v')
