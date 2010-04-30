namespace kri.meta

import OpenTK
import kri.shade


#---	stand-alone meta interface	---#
public interface IBase( par.INamed ):
	def clone() as IBase
	def link(d as rep.Dict) as void

public interface ISlave:
	def link(name as string, d as rep.Dict) as void

public interface IUnited:
	Unit as AdUnit:
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
	private unit	as AdUnit	= null
	def IBase.clone() as IBase:
		return copyTo( Advanced( Unit:unit ) )
	

#---	Unit Slave meta data	---#
public class AdUnit( ISlave, par.ValuePure[of kri.Texture] ):
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


#---	strand		---#
public class Strand(Advanced):
	# X = base thickness: [0,], Y = tip thickness: [0,], Z = shape: (-1,1)
	private final pData	= par.Value[of Vector4]('strand_data')
	portal Data		as Vector4	= pData.Value
	
	def IBase.clone() as IBase:
		return copyTo( Strand( Data:Data ))
	def IBase.link(d as rep.Dict) as void:
		d.var(pData)


#---	halo		---#
public class Halo(Advanced):
	private final pData	= par.Value[of Vector4]('halo_data')
	portal Data		as Vector4	= pData.Value
	
	def IBase.clone() as IBase:
		return copyTo( Halo( Data:Data ))
	def IBase.link(d as rep.Dict) as void:
		d.var(pData)


