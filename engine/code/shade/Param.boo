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

public class Texture(INamed, Value[of kri.Texture]):
	public final tun	as int
	[Getter(Name)]
	public final name	as string
	public def constructor(id as int, s as string):
		tun,name = id,s
	public def bindSlot(t as kri.Texture) as void:
		Value = t
		t.bind(tun)
	
	
public def create[of T](v as T) as Value[of T]:
	x = Value[of T]()
	x.Value = v
	return x



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
