namespace kri.shade.par

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


public class Texture(Value[of kri.Texture]):
	public def constructor(s as string):
		super(s)

public class TextureNew(Value[of kri.buf.Texture]):
	public def constructor(s as string):
		super(s)

/*	gives Failed to create 'kri.shade.par.Value2[of T]' type.. (BCE0055)
public class Value2[of T](ValueBase[of T]):
	[property(Value)]
	private val	as T
	public def constructor(s as string):
		super(s)
*/

public class UnitProxy( IBase[of kri.Texture] ):
	private final fun as callable() as kri.Texture
	public def constructor(f as callable() as kri.Texture):
		fun = f
	public override Value as kri.Texture:
		get: return fun()
