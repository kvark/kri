namespace kri.meta

import System
import OpenTK
import kri.shade


#---	stand-alone meta interface	---#

public interface IBase( par.INamed, ICloneable ):
	def link(d as par.Dict) as void

public interface ISlave( ICloneable ):
	def link(name as string, d as par.Dict) as void

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
	def IBase.link(d as par.Dict) as void:
		pass


#---	Advanced meta-data with unit link	---#
public class Advanced(IUnited,Hermit):
	[Property(Unit)]
	private unit	as int	= -1
	def ICloneable.Clone() as object:
		return copyTo( Advanced( Unit:unit ) )
	

#---	Unit Slave meta data	---#
public class AdUnit( ISlave, par.ValuePure[of kri.buf.Texture] ):
	public input	as Hermit	= null
	public final pOffset	= par.ValuePure[of Vector4]()
	public final pScale		= par.ValuePure[of Vector4]()
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value
	
	public def constructor():
		pOffset	.Value = Vector4.Zero
		pScale	.Value = Vector4.One
	
	def ICloneable.Clone() as object:
		return AdUnit( Value:Value, input:input, Offset:Offset, Scale:Scale )
	
	def ISlave.link(name as string, d as par.Dict) as void:
		d.unit(name,self)
		d['offset_'	+name] = pOffset
		d['scale_'	+name] = pScale
