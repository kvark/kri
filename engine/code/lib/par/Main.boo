namespace kri.lib.par

import System
import OpenTK
import OpenTK.Graphics
import kri.shade
import kri.meta

# light settings
public final class Light( IBase ):
	public final color	= par.Value[of Color4]('lit_color')
	public final attenu	= par.Value[of Vector4]('lit_attenu')
	public final data	= par.Value[of Vector4]('lit_data')

	public def activate(l as kri.Light) as void:
		color.Value		= l.Color
		kdir = (1f if l.fov>0f else 0f)
		attenu.Value	= Vector4(l.energy, l.quad1, l.quad2, l.sphere)
		data.Value		= Vector4(l.softness, kdir, 0f, 0f)

	par.INamed.Name as string:
		get: return 'Light'
	def ICloneable.Clone() as object:
		return self	# stub
	def IBase.link(d as par.Dict) as void:
		d.var(color)
		d.var(attenu,data)

# complete projector
public final class Project( IBase ):
	public final project	as proj.Shared
	public final spatial	as spa.Linked
	
	public def constructor(name as string):
		project = proj.Shared(name)
		spatial = spa.Linked('s_' + name)
	
	public def activate(p as kri.Projector) as void:
		project.activate( p )
		spatial.activate( p.node )
	
	par.INamed.Name as string:
		get: return project.Name
	def ICloneable.Clone() as object:
		return self	# stub
	def IBase.link(d as par.Dict) as void:
		for ib as IBase in (project,spatial):
			ib.link(d)
