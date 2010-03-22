namespace kri.lib.par

import System
import OpenTK
import OpenTK.Graphics


# light settings
public final class Light:
	public final color	= kri.shade.par.Value[of Color4]()
	public final attenu	= kri.shade.par.Value[of Vector4]()
	public final data	= kri.shade.par.Value[of Vector4]()
	public def activate(l as kri.Light) as void:
		color.Value		= l.Color
		kdir = (1f if l.fov>0f else 0f)
		attenu.Value	= Vector4(l.energy, l.quad1, l.quad2, l.sphere)
		data.Value		= Vector4(l.softness, kdir, 0f, 0f)
		return	if not l.depth
		id = kri.Ant.Inst.units.light
		kri.Ant.Inst.units.Tex[id] = l.depth
	public def constructor(d as kri.shade.rep.Dict):
		d.add('lit_color',	color)
		d.add('lit_attenu',	attenu)
		d.add('lit_data',	data)


# basic projector settins
public final class Project( kri.shade.par.Value[of Vector4] ):
	public def activate(p as kri.Projector) as void:
		div = 1f / (p.rangeIn - p.rangeOut)
		dad = div *(p.rangeIn + p.rangeOut)
		if p.fov > 0f:
			tn = 1f / Math.Tan(p.fov)
			Value = Vector4(tn, tn * p.aspect, dad,
				2f*div*(p.rangeIn*p.rangeOut) )
		else:
			Value = Vector4(-p.fov, -p.fov,	2f*div, dad)


# spatial settings of model/camera/light
public final class Spatial:
	public final position		= kri.shade.par.Value[of Vector4]()
	public final orientation	= kri.shade.par.Value[of Vector4]()
	public def activate(ref s as kri.Spatial) as void:
		position	.Value	= Vector4(s.pos, s.scale)
		orientation	.Value	= Vector4(s.rot.Xyz, s.rot.W)
	public def activate(n as kri.Node) as void:
		s = (n.World if n else kri.Spatial.Identity)
		activate(s)
	public def constructor(d as kri.shade.rep.Dict, n as string):
		d.add(n+'.pos', position)
		d.add(n+'.rot', orientation)
	public def constructor():
		pass
