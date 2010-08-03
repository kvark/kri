namespace kri.lib

import OpenTK
import kri.shade

# Shader Parameter Library
public final class Param:
	public final modelView	= par.spa.Shared('s_model')	# object->world
	public final light		= par.Light()
	public final litView	= par.spa.Shared('s_lit')	# light->world
	public final litProj	= par.Project('lit')	# light projection
	public final camView	= par.spa.Shared('s_cam')	# camera->world
	public final camProj	= par.Project('cam')	# camera projection
	public final parSize	= par.Value[of Vector4]('screen_size')	# viewport size
	public final parTime	= par.Value[of Vector4]('cur_time')		# task time & delta
	
	public def activate(c as kri.Camera) as void:
		kri.Camera.Current = c
		return	if not c
		camProj.activate(c)
		camView.activate( c.node )
	public def activate(l as kri.Light) as void:
		light.activate(l)
		litProj.activate(l)
		litView.activate( l.node )
	public def activate(fs as kri.frame.Screen) as void:
		parSize.Value = Vector4( 1f*fs.Width, 1f*fs.Height, 0.5f*(fs.Width+fs.Height), 0f)
		
	public def constructor(d as rep.Dict):
		for me in (of kri.meta.IBase: modelView, light,litView,litProj, camView,camProj):
			me.link(d)
		d.var(parSize,parTime)
