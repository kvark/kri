namespace kri.meta

import OpenTK
import OpenTK.Graphics
import kri.shade


#---	stand-alone meta interface	---#
public interface IBase( par.INamed ):
	def clone() as IBase
	def link(d as rep.Dict) as void

public interface IUnited:
	Unit as AdUnit:
		get

public interface IShaded:
	Shader as Object:
		get

public interface IAdvanced(IBase,IShaded,IUnited):
	pass


#---	Named meta-data with shader		---#
public class Hermit(IBase,IShaded):
	[Property(Name)]
	private name	as string	= ''
	[Property(Shader)]
	private shader	as Object	= null

	public def copyTo(h as Hermit) as Hermit:
		h.name = name
		h.shader = shader
		return h
	def IBase.clone() as IBase:
		return copyTo(Hermit())
	def IBase.link(d as rep.Dict) as void:
		pass


#---	Map Input : OBJECT		---#
public class InputObject(Hermit):
	public final pNode	= kri.lib.par.spa.Linked( Name:'s_target' )
	#don't inherit as the name is different
	def IBase.clone() as IBase:
		ib = InputObject()
		ib.pNode.activate( pNode.extract() )
		return copyTo(ib)
	def IBase.link(d as rep.Dict) as void:
		(pNode as IBase).link(d)


#---	Advanced meta-data with unit link	---#
public class Advanced(IAdvanced,Hermit):
	[Property(Unit)]
	private unit	as AdUnit	= null
	def IBase.clone() as IBase:
		return copyTo( Advanced( Unit:unit ) )
	

#---	Unit representor meta data with no shader	---#
public class AdUnit( IBase, par.Value[of kri.Texture] ):
	public input	as Hermit		= null
	public final pOffset	as par.Value[of Vector4]
	public final pScale		as par.Value[of Vector4]
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value
	
	public def constructor(s as string):
		super(s)
		pOffset	= par.Value[of Vector4]('offset_'+s)
		pScale	= par.Value[of Vector4]('scale_' +s)
	def IBase.clone() as IBase:
		un = AdUnit(Name)
		un.input = input
		un.Offset	= Offset
		un.Scale	= Scale
		return un
	def IBase.link(d as rep.Dict) as void:
		d.var(pOffset,pScale)


#---	real value meta-data	---#
public class Data[of T(struct)]( IAdvanced, par.Value[of T] ):
	[Property(Unit)]
	private unit	as AdUnit	= null
	[Property(Shader)]
	private shader	as Object	= null

	public def constructor(name as string):
		super( 'mat_'+name )
	public def constructor(un as AdUnit, sh as Object, pv as par.Value[of T]):
		super( pv.Name )
		unit,shader = un,sh
		Value = pv.Value
	def IBase.clone() as IBase:
		return Data[of T](unit,shader,self)
	def IBase.link(d as rep.Dict) as void:
		d.var(self)



#---	halo	---#
public class Halo(Advanced):
	private final pColor	= par.Value[of Color4]('halo_color')
	private final pData		= par.Value[of Vector4]('halo_data')
	private final pTex		= par.Value[of kri.Texture]('halo')
	portal Color	as Color4	= pColor.Value
	portal Data		as Vector4	= pData.Value
	portal Tex		as kri.Texture	= pTex.Value
	
	def IBase.clone() as IBase:
		return copyTo( Halo( Color:Color, Data:Data, Tex:Tex ))
	def IBase.link(d as rep.Dict) as void:
		d.var(pColor)
		d.var(pData)
		d.unit(pTex)
