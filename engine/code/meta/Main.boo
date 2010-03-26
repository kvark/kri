namespace kri.meta

import OpenTK
import OpenTK.Graphics
import kri.shade

public static class Scalars:	# deprecated!
	public final name	= 'mat_scalars'

public interface IValued[of T(struct)]:
	Value as T:
		get
		set


#---	Basic meta-data		---#
public class Basic:
	public shader	as Object	= null	# shader port
	public virtual def clone() as Basic:
		return Basic(shader:shader)
	public virtual def link(d as rep.Dict) as void:
		pass

public class Hermit(Basic):
	[Property(Name)]
	protected name	as string	= ''

#---	Map Input : OBJECT		---#
public class InputObject(Hermit):
	public final pNode	= kri.lib.par.spa.Linked()
	public override def link(d as rep.Dict) as void:
		pNode.link(d,'s_target')


public class Advanced(Hermit):
	public unit	as AdUnit	= null
	protected def copyTo(m as Advanced) as void:
		m.shader = shader
		m.unit = unit
	public override def clone() as Basic:
		m = Advanced()
		copyTo(m)
		return m
	

public class AdUnit( Hermit, par.ITexture ):
	public input	as Hermit		= null
	[Property(Value)]
	private tex		as kri.Texture	= null
	#required to bypass BOO-1294
	public Name2 	as string:
		get: return name

	public final pOffset	= par.Value[of Vector4]()
	public final pScale		= par.Value[of Vector4]()
	
	public override def link(d as rep.Dict) as void:
		d.add('offset_'+Name, pOffset)
		d.add('scale_' +Name, pScale)

[ext.spec.Class(single,Color4)]
[ext.RemoveSource()]
public class Data[of T(struct)]( Advanced, IValued[of T] ):
	private final pVal	= par.Value[of T]()
	portal Value as T	= pVal.Value
	public override def link(d as rep.Dict) as void:
		d.add('mat_'+name, pVal)


#---	Map texture meta-unit	---#
public class Unit():
	public tex	as kri.Texture	= null
	public final liMeta		as Basic	# linked meta data
	public final generator	as Object	# to generate the coordinate
	public final sampler	as Object	# to sample from the texture

	private final pOffset	= par.Value[of Vector4]()
	private final pScale	= par.Value[of Vector4]()
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value

	public def constructor(linkedMeta as Basic, sh_gen as Object, sh_use as Object):
		liMeta,generator,sampler = linkedMeta,sh_gen,sh_use
		self.Offset	= Vector4.Zero
		self.Scale	= Vector4.One
	public def constructor(u as Unit):
		liMeta = u.liMeta
		generator = u.generator
		sampler = u.sampler
		tex = u.tex
		self.Offset = u.Offset
		self.Scale = u.Scale
	public def link(d as rep.Dict, name as string) as void:
		liMeta.link(d)	if liMeta
		d.add('offset_'+name, pOffset)
		d.add('scale_' +name, pScale)


#----------------------
# problem: shared pData will not be cloned properly

public class Emission( Basic, kri.IColored ):
	private final pCol	= par.Value[of Color4]()
	portal Color		as Color4	= pCol.Value

	public def constructor():
		self.Color = Color4.Gray
	public override def clone() as Basic:
		m = Emission()
		m.Color = Color
		return m
	public override def link(d as rep.Dict) as void:
		d.add('mat.emissive', pCol)


public class Diffuse( Basic, kri.IColored ):
	private final pCol	= par.Value[of Color4]()
	private final pData	as par.Value[of Vector4]
	portal Color		as Color4	= pCol.Value
	portal Reflection	as single	= pData.Value.X
	
	public def constructor(pd as par.Value[of Vector4]):
		pData = pd
		self.Color = Color4.Gray
		self.Reflection = 1f
	public override def clone() as Basic:
		m = Diffuse(pData)
		m.Color = Color
		m.Reflection = Reflection
		return m
	public override def link(d as rep.Dict) as void:
		d.add('mat.diffuse', pCol)
		if not Scalars.name in d:
			d.add(Scalars.name, pData)


public class Specular( Basic, kri.IColored ):
	private final pCol	= par.Value[of Color4]()
	private final pData	as par.Value[of Vector4]
	portal Color		as Color4	= pCol.Value
	portal Specularity	as single	= pData.Value.Y
	portal Glossiness	as single	= pData.Value.Z
	
	public def constructor(pd as par.Value[of Vector4]):
		pData = pd
		self.Color = Color4.Gray
		self.Specularity	= 1f
		self.Glossiness		= 10f
	public override def clone() as Basic:
		m = Specular(pData)
		m.Color = Color
		m.Specularity	= Specularity
		m.Glossiness	= Glossiness
		return m
	public override def link(d as rep.Dict) as void:
		d.add('mat.specular', pCol)
		if not Scalars.name in d:
			d.add(Scalars.name, pData)


public class Parallax( Basic ):
	private final pData	as par.Value[of Vector4]
	portal Shift	as single	= pData.Value.W
	
	public def constructor(pd as par.Value[of Vector4]):
		pData = pd
		self.Shift = 0f
	public override def clone() as Basic:
		m = Parallax(pData)
		m.Shift = Shift
		return m
	public override def link(d as rep.Dict) as void:
		if not Scalars.name in d:
			d.add(Scalars.name, pData)
