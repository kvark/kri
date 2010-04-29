namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public interface ISemanted:
	Semant	as List[of Info]:
		get

public def enrich(ob as ISemanted, size as byte, *slots as (int)) as void:
	for at in slots:
		ob.Semant.Add( Info(
			integer:false, size:size, slot:at,
			type: VertexAttribPointerType.Float ))


public class Attrib( ISemanted, Object ):
	[Getter(Semant)]
	private final semantics	as List[of Info]	= List[of Info]()

	public def constructor():
		super( BufferTarget.ArrayBuffer )
	
	public def unitLoc(ref at as Info, ref off as int, ref sum as int) as bool:
		off,sum = -1,0
		for ain in semantics:
			if ain.slot == at.slot:
				assert off<0
				off = sum
				at = ain
			sum += ain.fullSize()
		return off >= 0
	public def unitSize() as int:
		rez = 0
		for a in semantics:
			rez += a.fullSize()
		return rez
	
	public def initAll(num as int) as void:
		off,total = 0,unitSize()
		init(num * total)
		semantics.ForEach() do(ref at as Info):
			Push(at, off, total)
			off += at.fullSize()

	private static def Push(ref at as Info, off as int, total as int) as void:
		GL.EnableVertexAttribArray( at.slot )
		if at.integer: #TODO: use proper enum
			GL.VertexAttribIPointer( at.slot, at.size,
				cast(VertexAttribIPointerType,cast(int,at.type)),
				total, System.IntPtr(off) )
		else:
			GL.VertexAttribPointer(at.slot, at.size,
				at.type, false, total, off)
				
	private def push(ref at as Info) as void:
		off,sum = 0,0
		unitLoc(at,off,sum)	# no modification here
		Push(at,off,sum)

	public def attrib(id as uint) as bool:
		at = Info( slot:id )
		off,sum = 0,0
		if not unitLoc(at,off,sum):
			return false
		bind()
		Push(at,off,sum)
		return true
			
	public def attribFirst() as void:
		bind()
		ai = semantics[0]
		push(ai)
	
	public def attribFake(slot as uint) as void:
		bind()
		ai = semantics[0]
		ai.slot = slot
		push(ai)

	public def attribTrans(dict as IDictionary[of int,int]) as void:
		bind()
		off,total = 0,unitSize()
		for at in semantics:
			val = 0
			if dict.TryGetValue(at.slot,val):
				a2 = at
				a2.slot = val
				Push(a2,off,total)
			off += at.fullSize()
