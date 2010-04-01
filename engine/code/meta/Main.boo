namespace kri.meta

import OpenTK
import OpenTK.Graphics
import kri.shade

public interface IValued[of T(struct)]:
	Value as T:
		get
		set


#---	stand-alone meta interface	---#
public interface IBase( par.INamed ):
	def clone() as IBase
	def link(d as rep.Dict) as void


#---	Named meta-data with shader		---#
public class Hermit(IBase):
	[Property(Name)]
	private name	as string	= ''
	public shader	as Object	= null

	public def copyTo(h as Hermit) as Hermit:
		h.name = name
		h.shader = shader
		return h
	
	def IBase.clone() as IBase:
		return copyTo( Hermit() )
	def IBase.link(d as rep.Dict) as void:
		pass


#---	Map Input : OBJECT		---#
public class InputObject(Hermit):
	public final pNode	= kri.lib.par.spa.Linked( Name:'s_target' )
	def IBase.clone() as IBase:
		ib = InputObject()
		ib.pNode.activate( pNode.extract() )
		return copyTo(ib)
	def IBase.link(d as rep.Dict) as void:
		(pNode as IBase).link(d)


#---	Advanced meta-data with unit link	---#
public class Advanced(Hermit):
	public unit	as AdUnit	= null
	def IBase.clone() as IBase:
		return copyTo( Advanced( unit:unit ) )
	

#---	Unit representor meta data with no shader	---#
public class AdUnit( IBase, par.Value[of kri.Texture] ):
	public input	as Hermit		= null
	[Property(Name)]
	private name	as string	= ''

	public final pOffset	= par.Value[of Vector4]()
	public final pScale		= par.Value[of Vector4]()
	
	def IBase.clone() as IBase:
		un = AdUnit( input:input, Name:name )
		un.pOffset.Value	= pOffset.Value
		un.pScale.Value		= pScale.Value
		return un
	def IBase.link(d as rep.Dict) as void:
		d.add('offset_'+Name, pOffset)
		d.add('scale_' +Name, pScale)


#---	real value meta-data	---#
[ext.spec.Class(single,Color4,Vector4)]
[ext.RemoveSource()]
public class Data[of T(struct)]( Advanced, IValued[of T] ):
	private final pVal	= par.Value[of T]()
	portal Value as T	= pVal.Value
	def IBase.clone() as IBase:
		return copyTo( Data[of T]( Value:Value, unit:unit ))
	def IBase.link(d as rep.Dict) as void:
		d.add('mat_'+Name, pVal)
