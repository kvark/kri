namespace kri.meta

import OpenTK
import OpenTK.Graphics
import kri.shade


#---	stand-alone meta interface	---#
public interface IBase( par.INamed ):
	def clone() as IBase
	def link(d as rep.Dict) as void

public interface ISlave:
	def link(name as string, d as rep.Dict) as void

public interface IUnited:
	Unit as AdUnit2:
		get

public interface IShaded:
	Shader as Object:
		get


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
	public final pNode	= kri.lib.par.spa.Linked('s_target')
	#don't inherit as the name is different
	def IBase.clone() as IBase:
		ib = InputObject()
		ib.pNode.activate( pNode.extract() )
		return copyTo(ib)
	def IBase.link(d as rep.Dict) as void:
		(pNode as IBase).link(d)


#---	Advanced meta-data with unit link	---#
public class Advanced(IUnited,Hermit):
	[Property(Unit)]
	private unit	as AdUnit2	= null
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


#---	Unit Slave meta data	---#
public class AdUnit2( ISlave, par.ValuePure[of kri.Texture] ):
	public input	as Hermit	= null
	public final pOffset	= par.ValuePure[of Vector4]()
	public final pScale		= par.ValuePure[of Vector4]()
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value
	
	def ISlave.link(name as string, d as rep.Dict) as void:
		d.unit(name,self)
		d['offset_'	+name] = pOffset
		d['scale_'	+name] = pScale




#---	real value meta-data	---#
public class Data[of T(struct)]( Advanced ):
	private final data	as par.Value[of T]
	portal Value	as T	= data.Value
	
	public def constructor(s as string, sh as Object, val as T):
		data = par.Value[of T]( 'mat_'+s )
		Name = s
		Shader = sh
		Value = val
	def IBase.clone() as IBase:
		d2 = Data[of T](Name,Shader,Value)
		d2.Unit = Unit
		return d2
	def IBase.link(d as rep.Dict) as void:
		d.var(data)



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
