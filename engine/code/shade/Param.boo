namespace kri.shade.par

import System


#-----------------------#
#	AUTO PARAMETERS 	#
#-----------------------#

public interface IBase[of T]:
	Value	as T:
		get

public interface INamed:
	Name	as string:
		get
		

public class Value[of T](IBase[of T]):
	[property(Value)]
	private val	as T

	
public def create[of T](v as T) as Value[of T]:
	x = Value[of T]()
	x.Value = v
	return x

# Simple shader parameter
public class Basic[of T](Value[of T]):
	public final name as string
	public def constructor(str as string):
		name = str


public class Cached[of T]():
	protected cached	as T
	private final p		as IBase[of T]
	protected def constructor(par as IBase[of T]):
		p = par
	public def update() as bool:
		return false	if p.Value == cached
		cached = p.Value
		return true


# Abstract Parameter for GL context
public class System[of T](Cached[of T],IBase[of T]):
	[property(Value)]
	private val	as T
	public def constructor():
		super(self)


public class Unit(Value[of kri.Texture]):
	pass
