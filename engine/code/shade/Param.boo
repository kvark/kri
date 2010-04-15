namespace kri.shade.par

import System

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


public class Value[of T](IBase[of T],INamed):
	[property(Value)]
	private val	as T
	[Getter(Name)]
	private final name	as string
	public def constructor(s as string):
		name = s
