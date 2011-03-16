namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public interface ISemanted:
	Semant	as List[of Info]:
		get


public class Attrib( ISemanted, Object ):
	[Getter(Semant)]
	private final semantics	as List[of Info]	= List[of Info]()

	public def constructor():
		super( BufferTarget.ArrayBuffer )
	
	public def unitLoc(ref at as Info, ref off as int, ref sum as int) as bool:
		off,sum = -1,0
		for ain in semantics:
			if ain.name == at.name:
				assert off<0
				off = sum
				at = ain
			sum += ain.fullSize()
		return off >= 0

	public def unitSize() as uint:
		rez as uint = 0
		for a in semantics:
			rez += a.fullSize()
		return rez
	
	public def initUnit(num as uint) as void:
		init( num * unitSize() )
	
	private def initAll(num as int) as void:
		off,total = 0,unitSize()
		assert not 'supported'	# slot=?
		if num<0:	bind()
		else:	init(num * total)
		semantics.ForEach() do(ref at as Info):
			#Push(0, at, off, total)
			off += at.fullSize()

	private def push(ref at as Info) as void:
		off,sum = 0,0
		unitLoc(at,off,sum)	# no modification here
		assert not 'supported'	# slot=?
		#Push(0,at,off,sum)

	private def attrib(name as string) as bool:
		at = Info( name:name )
		off,sum = 0,0
		if not unitLoc(at,off,sum):
			return false
		bind()
		assert not 'supported'	# slot=?
		#Push(0,at,off,sum)
		return true
			
	private def attribFirst() as void:
		bind()
		ai = semantics[0]
		push(ai)
	
	private def attribFake(name as string) as void:
		bind()
		ai = semantics[0]
		ai.name = name
		push(ai)

	private def attribTrans(dict as IDictionary[of string,string]) as void:
		bind()
		#off,total = 0,unitSize()
		for at in semantics:
			val = ''
			if dict.TryGetValue(at.name,val):
				a2 = at
				a2.name = val
				assert not 'supported'	# slot=?
				#Push(0,a2,off,total)
			#off += at.fullSize()
