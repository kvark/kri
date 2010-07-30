namespace kri.lib

import System


# Constant Storage
public static class Const:
	public final nTech		= 24	# Render Techniques
	public final nAttrib	= 16	# Vertex Attributes
	public final nPart		= 16	# Particle Data


# Manages integer slots represented by names 
public struct Slot:
	[getter(Name)]
	private final lib as (string)
	public def constructor(num as int):
		lib = array[of string](num)
	public Size as int:
		get: return lib.Length
	public def create(name as string) as int:
		assert find(name)<0
		id = Array.FindIndex( lib, string.IsNullOrEmpty )
		lib[id] = name	if id>=0
		return id
	# let it live until Ant dies
	public def delete(id as int) as bool:
		#return false	if lib[id] is null
		#lib[id] = null
		return true
	internal def clear() as void:
		lib.Initialize()
	public def find(name as string) as int:
		return Array.FindIndex(lib) do(s as string):
			return s == name
	public def find(num as uint) as (int):
		sar = List[of int]()
		for i in range(lib.Length):
			if string.IsNullOrEmpty(lib[i]):
				sar.Add(i)
				break	if sar.Count == num
		return sar.ToArray()
	public def getForced(name as string) as int:
		id = find(name)
		return (id if id>=0 else create(name))


public final class Attrib:
	public final vertex		as int
	public final quat		as int
	public final tex		= (of int: 0,0,0,0)
	public final color		= (of int: 0)
	internal def constructor(s as Slot):
		vertex	= s.getForced('vertex')
		quat	= s.getForced('quat')
		for i in range(tex.Length):
			tex[i]		= s.getForced('tex'+i)
		for i in range(color.Length):
			color[i]	= s.getForced('color'+i)
