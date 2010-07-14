namespace kri.meta

import System
import OpenTK
import kri.shade


#---	stand-alone meta interface	---#

public interface IBase( par.INamed, ICloneable ):
	def link(d as rep.Dict) as void

public interface ISlave( ICloneable ):
	def link(name as string, d as rep.Dict) as void

public interface IUnited:
	Unit as int:
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
	def ICloneable.Clone() as object:
		return copyTo(Hermit())
	def IBase.link(d as rep.Dict) as void:
		pass


#---	Map Input : OBJECT		---#
public class InputObject(Hermit):
	public final pNode	= kri.lib.par.spa.Linked('s_target')
	#don't inherit as the name is different
	def ICloneable.Clone() as object:
		ib = InputObject()
		ib.pNode.activate( pNode.extract() )
		return copyTo(ib)
	def IBase.link(d as rep.Dict) as void:
		(pNode as IBase).link(d)


#---	Advanced meta-data with unit link	---#
public class Advanced(IUnited,Hermit):
	[Property(Unit)]
	private unit	as int	= -1
	def ICloneable.Clone() as object:
		return copyTo( Advanced( Unit:unit ) )
	

#---	Unit Slave meta data	---#
public class AdUnit( ISlave, par.ValuePure[of kri.Texture] ):
	public input	as Hermit	= null
	public final pOffset	= par.ValuePure[of Vector4]()
	public final pScale		= par.ValuePure[of Vector4]()
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value
	
	def ICloneable.Clone() as object:
		return AdUnit( Value:Value, input:input, Offset:Offset, Scale:Scale )
	
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
	def ICloneable.Clone() as object:
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
	
	def ICloneable.Clone() as object:
		return copyTo( Strand( Data:Data ))
	def IBase.link(d as rep.Dict) as void:
		d.var(pData)


#---	halo		---#
public class Halo(Advanced):
	private final pData	= par.Value[of Vector4]('halo_data')
	portal Data		as Vector4	= pData.Value
	
	def ICloneable.Clone() as object:
		return copyTo( Halo( Data:Data ))
	def IBase.link(d as rep.Dict) as void:
		d.var(pData)

#---	instance	---#
public class Inst(Advanced):
	public ent	as kri.Entity	= null
	def ICloneable.Clone() as object:
		return copyTo( Inst( ent:ent ))
	def IBase.link(d as rep.Dict) as void:
		pass
