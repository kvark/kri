namespace kri.part

import System
import OpenTK.Graphics.OpenGL


private class DataHolder:
	internal data	as kri.vb.Attrib	= null
	internal va		= kri.vb.Array()
	internal def init(sem as kri.vb.attr.Info*, num as uint):
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
	public onDraw	as callable()	= null
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
	public def draw() as void:
		assert sa
		onDraw()	if onDraw
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
	public final	g_init	= kri.shade.Object('/part/init_g')
	public final	sh_draw	= kri.shade.Object('/part/draw/main_v')
	public final	sh_root	= kri.shade.Object('/part/root_v')
	# born shaders
	public final	sh_born_instant	= kri.shade.Object('/part/born/instant_v')
	public final	sh_born_time	= kri.shade.Object('/part/born/time_v')
	# emit surface shaders
	public final	sh_surf_node	= kri.shade.Object('/part/surf/node_v')
	public final	sh_surf_vertex	= kri.shade.Object('/part/surf/vertex_v')
	public final	sh_surf_face	= kri.shade.Object('/part/surf/face_v')
