namespace kri.part

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


private class DataHolder:
	internal data	= kri.vb.Attrib()
	internal va	= kri.vb.Array()


#---------------------------------------#
#	PARTICLE GENERIC BEHAVIOR			#
#---------------------------------------#

public class Behavior:
	public final code	as string	= null
	public final semantics = List[of kri.vb.attr.Info]()
	public final sh		as kri.shade.Object

	public def constructor(path as string):
		code = kri.shade.Object.readText(path)
		sh = kri.shade.Object( ShaderType.VertexShader, 'beh', code )
	public def getMethod(base as string) as string:
		return ''	if string.IsNullOrEmpty(code)
		pos = code.IndexOf(base)
		p2 = code.IndexOf('()',pos)
		assert pos>=0 and p2>=0
		return code.Substring(pos,p2+2-pos)


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

	public def init() as void:
		va.bind()
		data.semantics.AddRange( man.data.semantics )
		data.initAll( man.total )
		#man.reset(self)
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
		init()
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
	public final	sh_draw	= kri.shade.Object('/part/draw_v')
	public final	sh_root	= kri.shade.Object('/part/root_v')
	# born shaders
	public final	sh_born_instant	= kri.shade.Object('/part/born/instant_v')
	public final	sh_born_time	= kri.shade.Object('/part/born/time_v')
	# emit surface shaders
	public final	sh_surf_node	= kri.shade.Object('/part/surf/node_v')
	public final	sh_surf_vertex	= kri.shade.Object('/part/surf/vertex_v')
	public final	sh_surf_face	= kri.shade.Object('/part/surf/face_v')


#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager(DataHolder):
	private final tf	= kri.TransFeedback(1)
	private final prog_init		= kri.shade.Smart()
	private final prog_update	= kri.shade.Smart()
	private final factory	= kri.ShaderLinker( kri.Ant.Inst.slotParticles )
	
	public onUpdate	as callable(kri.Entity)	= null
	public final behos	= List[of Behavior]()
	public final dict	= kri.shade.rep.Dict()
	public final total	as uint
	public final shaders	= List[of kri.shade.Object]()
	public sh_born		as kri.shade.Object	= null

	private parTotal	= kri.shade.par.Value[of single]()
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num
		dict.add('part_total', parTotal)

	private def collect(type as string, method as string, inter as string, oper as string) as kri.shade.Object:
		names = [b.getMethod(method+'_') for b in behos]
		decl = join("${type} ${n};\n"	for n in names)
		body = join("${oper}\n\t${n}"	for n in names)
		all = "#version 130\n${decl}\n${type} ${method}()\t{${inter}${body};\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)
			
		
	public def init(pc as Context) as void:
		sl = kri.Ant.Inst.slotParticles
		def id2out(id as int) as string:
			return 'to_' + sl.Name[id]
		data.semantics.Clear()
		data.semantics.Add( kri.vb.attr.Info(
			slot:pc.at_sys, size:3,
			type:VertexAttribPointerType.Float ))

		sh_init = collect('void', 'init', '', ';')
		sh_reset = collect('void', 'reset', '', ';')
		sh_update = collect('float', 'update', 'return 1.0', '*')
		out_names = List[of string]()
		out_names.Add( id2out( pc.at_sys ) )
		for b in behos:
			for at in b.semantics:
				out_names.Add( id2out(at.slot) )
				data.semantics.Add( at )
			prog_init.add( b.sh )
			prog_update.add( b.sh )
		
		va.bind()	# has to be after behaviors
		data.initAll(total)
		
		prog_init.add('quat')
		prog_init.add( sh_init, pc.v_init )
		tf.Setup(prog_init, false, *out_names.ToArray())
		prog_init	.link( sl, dict, kri.Ant.Inst.dict )
		
		assert sh_born
		prog_update.add( *shaders.ToArray() )
		prog_update.add('quat')
		prog_update.add( sh_reset, sh_update, sh_born, pc.sh_root )
		tf.Setup(prog_update, false, *out_names.ToArray())
		prog_update	.link( sl, dict, kri.Ant.Inst.dict )
	
	private def process(pe as Emitter, prog as kri.shade.Program) as void:
		onUpdate( pe.obj )	if onUpdate
		va.bind()
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		prog.use()
		using kri.Discarder(true), tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, total )
		
	public def reset(pe as Emitter) as void:
		process(pe, prog_init)

	public def tick(pe as Emitter) as void:
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
		process(pe, prog_update)


#---------------------------------------------------#
#	STANDARD MANAGER FOR LOADED PARTICLES			#
#---------------------------------------------------#

public class Standard(Manager):
	public final parSize	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parLife	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parVelTan	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parVelObj	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parVelKeep	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parForce	= kri.shade.par.Value[of OpenTK.Vector4]()
	public final parForceWorld	= kri.shade.par.Value[of OpenTK.Vector4]()

	public def constructor(num as uint):
		super(num)
		dict.add('part_size',	parSize)
		dict.add('part_life',	parLife)
		dict.add('part_speed_tan',	parVelTan)
		dict.add('part_speed_obj',	parVelObj)
		dict.add('object_speed',	parVelKeep)
		dict.add('part_force',	parForce)
		dict.add('force_world', parForceWorld)
