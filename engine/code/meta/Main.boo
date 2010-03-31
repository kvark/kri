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
	public shader	as Object	= null
	[Property(Name)]
	private name	as string	= ''
	
	def IBase.clone() as IBase:
		return Hermit( shader:shader, Name:Name )
	def IBase.link(d as rep.Dict) as void:
		pass


#---	Map Input : UV		---#
public class InputUV(Hermit):
	public final pInd	= par.Value[of int]()
	def IBase.link(d as rep.Dict) as void:
		d.add('index',pInd)
		
#---	Map Input : OBJECT		---#
public class InputObject(Hermit):
	public final pNode	= kri.lib.par.spa.Linked()
	def IBase.link(d as rep.Dict) as void:
		pNode.link(d,'s_target')


#---	Advanced meta-data with unit link	---#
public class Advanced(Hermit):
	public unit	as AdUnit	= null
	

#---	Unit representor meta data with no shader	---#
public class AdUnit( IBase, par.Value[of kri.Texture] ):
	public input	as Hermit		= null
	[Property(Name)]
	private name	as string	= ''

	public final pOffset	= par.Value[of Vector4]()
	public final pScale		= par.Value[of Vector4]()
	
	def IBase.clone() as IBase:
		return null
	def IBase.link(d as rep.Dict) as void:
		d.add('offset_'+Name, pOffset)
		d.add('scale_' +Name, pScale)


#---	real value meta-data	---#
[ext.spec.Class(Color4,single)]
[ext.RemoveSource()]
public class Data[of T(struct)]( Advanced, IValued[of T] ):
	private final pVal	= par.Value[of T]()
	portal Value as T	= pVal.Value
	def IBase.link(d as rep.Dict) as void:
		d.add('mat_'+Name, pVal)
