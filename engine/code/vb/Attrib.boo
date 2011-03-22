namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public interface IBuffed:
	Data	as Object:
		get

public interface ISemanted:
	Semant	as List[of Info]:
		get

public interface IProvider(IBuffed,ISemanted):
	pass



public class Attrib( IProvider, Object ):
	[Getter(Semant)]
	private final semantics	as List[of Info]	= List[of Info]()
	IBuffed.Data		as Object:
		get: return self

	public def constructor():
		super( BufferTarget.ArrayBuffer )
	
	public def unitSize() as uint:
		rez as uint = 0
		for a in semantics:
			rez += a.fullSize()
		return rez
	
	public def initUnit(num as uint) as void:
		init( num * unitSize() )

