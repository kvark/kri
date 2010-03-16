namespace kri.meta

import System
import OpenTK
import OpenTK.Graphics
import kri.shade


#----------------------

public class Basic( kri.IApplyable, ICloneable ):
	public shader	as Object	= null	# implementation shader
	public def Clone() as object:			# ICloneable.Clone
		return Basic(shader:shader)
	public virtual def apply() as void:		# IApplyable.apply
		pass


public class Unit:
	public tex	as kri.Texture
	public final generator	as Object	# to generate the coordinate
	public final sampler	as Object	# to sample from the texture
	# offset & scale for the texture coords
	public final trans	= (par.Value[of Vector3](), par.Value[of Vector3]())
	public def constructor(sh_gen as Object, sh_use as Object):
		generator,sampler = sh_gen,sh_use
		trans[0].Value = Vector3.Zero
		trans[1].Value = Vector3.One


#----------------------

public class Emission(Basic):
	private final pCol	as par.Value[of Color4]
	public color		= Color4(0f,0f,0f,1f)
	public def constructor(pc as par.Value[of Color4]):
		pCol = pc
	public def Clone() as object:
		m = Emission(pCol)
		m.color = color
		return m
	public override def apply() as void:
		pCol.Value = color


public class Diffuse(Basic):
	private final pCol	as par.Value[of Color4]
	private final pData	as par.Value[of Vector4]
	public color		= Color4(0.5f,0.5f,0.5f,1f)
	public kReflection	= 1f
	public def constructor(pc as par.Value[of Color4], pd as par.Value[of Vector4]):
		pCol,pData = pc,pd
	public def Clone() as object:
		m = Diffuse(pCol,pData)
		m.color = color
		m.kReflection = kReflection
		return m
	public override def apply() as void:
		pData.Value.X = kReflection
		pCol.Value = color


public class Specular(Basic):
	private final pCol	as par.Value[of Color4]
	private final pData	as par.Value[of Vector4]
	public color		= Color4(0.5f,0.5f,0.5f,1f)
	public kSpecularity	= 1f
	public kGlossiness	= 10f
	public def constructor(pc as par.Value[of Color4], pd as par.Value[of Vector4]):
		pCol,pData = pc,pd
	public def Clone() as object:
		m = Specular(pCol,pData)
		m.color = color
		m.kSpecularity = kSpecularity
		m.kGlossiness = kGlossiness
		return m
	public override def apply() as void:
		pData.Value.Y = kSpecularity
		pData.Value.Z = kGlossiness
		pCol.Value = color


public class Parallax(Basic):
	private final pData	as par.Value[of Vector4]
	public kShift	as single	= 0f
	public def constructor(pd as par.Value[of Vector4]):
		pData = pd
	public def Clone() as object:
		m = Parallax(pData)
		m.kShift = kShift
		return m
	public override def apply() as void:
		pData.Value.W = kShift
