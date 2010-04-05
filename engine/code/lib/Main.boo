namespace kri.lib

import System
import System.Collections.Generic
import OpenTK


# Shader Parameter Library
public final class Param:
	public final modelView	= par.spa.Shared( Name:'s_model' )	# object->world
	public final light		= par.Light()
	public final litView	= par.spa.Shared( Name:'s_lit' )	# light->world
	public final litProj	= par.Project( Name:'lit' )	# light projection
	public final camView	= par.spa.Shared( Name:'s_cam' )	# camera->world
	public final camProj	= par.Project( Name:'cam' )	# camera projection
	public final parSize	= kri.shade.par.Value[of Vector4]()	# viewport size
	public final parTime	= kri.shade.par.Value[of Vector4]()	# task time & delta
	
	public def activate(c as kri.Camera) as void:
		kri.Camera.Current = c
		return	if not c
		camProj.activate(c)
		camView.activate( c.node )
	public def activate(l as kri.Light) as void:
		light.activate(l)
		litProj.activate(l)
		litView.activate( l.node )
		
	public def constructor(d as kri.shade.rep.Dict):
		for me in (of kri.meta.IBase: modelView, light,litView,litProj, camView,camProj):
			me.link(d)
		d.add('screen_size',	parSize)
		d.add('cur_time',		parTime)


# Shader Objects & Programs Library
public class Shader( Dictionary[of string, kri.shade.Object] ):
	public final header = "#version 130\n precision lowp float;\n"
	public final gentleSet as (kri.shade.Object)
	public def constructor():
		super()
		for str in ('quat','tool','fixed','orient'):
			Add(str, kri.shade.Object("/lib/${str}_v") )
		Add('math', kri.shade.Object('/lib/math_f'))
		gentleSet = array(Values)
		for str in ('copy_v','copy_f','copy_ar_f'):
			Add(str, kri.shade.Object('/'+str))
		Add('empty', kri.shade.Object('/empty_f'))
