namespace kri.lib

import System
import System.Collections.Generic
import OpenTK


# Shader Parameter Library
public final class Param:
	public final light		as par.Light
	public final modelView	as par.Spatial	# object->world
	public final lightView	as par.Spatial	# light->world
	public final lightProj	= par.Project()	# light projection
	public final camView	as par.Spatial	# camera->world
	public final camProj	= par.Project()	# camera projection
	public final parSize	= kri.shade.par.Value[of Vector4]()	# viewport size
	public final parTime	= kri.shade.par.Value[of Vector4]()	# task time & delta
	
	public def activate(c as kri.Camera) as void:
		kri.Camera.Current = c
		return	if not c
		camProj.activate(c)
		return	if not c.node
		camView.activate(c.node)
		
	public def constructor(d as kri.shade.rep.Dict):
		light = par.Light(d)
		modelView	= par.Spatial(d,'s_model')
		lightView	= par.Spatial(d,'s_lit')
		camView		= par.Spatial(d,'s_cam')
		d.add('proj_lit',		lightProj)
		d.add('proj_cam',		camProj)
		d.add('screen_size',	parSize)
		d.add('cur_time',		parTime)


# Shader Objects & Programs Library
public class Shader( Dictionary[of string, kri.shade.Object] ):
	public final gentleSet as (kri.shade.Object)
	public def constructor():
		super()
		for str in ('copy_v','copy_f','copy_ar_f'):
			Add(str, kri.shade.Object('/'+str))
		Add('empty',	kri.shade.Object('/empty_f'))
		Add('quat',		kri.shade.Object('/lib/quat_v'))
		Add('tool',		kri.shade.Object('/lib/tool_v'))
		Add('fixed',	kri.shade.Object('/lib/fixed_v'))
		Add('math',		kri.shade.Object('/lib/math_f'))
		gentleSet = (self['quat'],self['tool'],self['fixed'],self['math'])
