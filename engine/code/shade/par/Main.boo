namespace kri.shade.par

import System.Collections.Generic

#-----------------------#
#	AUTO PARAMETERS 	#
#-----------------------#

public interface IBaseRoot:
	pass

public interface IBase[of T](IBaseRoot):
	Value	as T:
		get

public interface INamed:
	Name	as string:
		get


public class ValuePure[of T]( IBase[of T] ):
	[Property(Value)]
	private val	as T


public abstract class ValueBase[of T]( IBase[of T],INamed ):
	[Getter(Name)]
	private final name	as string
	public def constructor(s as string):
		name = s


public class Value[of T](IBase[of T],INamed):
	[Property(Value)]
	private val	as T
	[Getter(Name)]
	private final name	as string
	public def constructor(s as string):
		name = s


public class Texture(Value[of kri.buf.Texture]):
	public def constructor(s as string):
		super(s)


public class Proxy[of T](IBase[of T]):
	public base	as IBase[of T]	= null
	public Value as T:
		get: return base.Value


/*	gives Failed to create 'kri.shade.par.Value2[of T]' type.. (BCE0055)
public class Value2[of T](ValueBase[of T]):
	[property(Value)]
	private val	as T
	public def constructor(s as string):
		super(s)
*/

public class UnitProxy( IBase[of kri.buf.Texture] ):
	private final fun as callable() as kri.buf.Texture
	public def constructor(f as callable() as kri.buf.Texture):
		fun = f
	public override Value as kri.buf.Texture:
		get: return fun()


# Standard uniform dictionary
public class Dict( SortedDictionary[of string,IBaseRoot] ):
	public virtual def find(ref uni as kri.shade.Uniform) as IBaseRoot:
		return null
	# copy contents of another dictionary
	public def attach(d as Dict) as void:
		for u in d:
			Item[u.Key] = u.Value
	# add standard uniform
	public def var[of T](*var as (Value[of T])) as void:
		for v in var:
			Item[v.Name] = v
	# add custom unit
	public def unit(name as string, v as IBase[of kri.buf.Texture]) as void:
		Item[kri.shade.Mega.PrefixUnit + name] = v
	# add texture unit representor
	public def unit(*vat as (Value[of kri.buf.Texture])) as void:
		for v in vat:
			unit(v.Name,v)
