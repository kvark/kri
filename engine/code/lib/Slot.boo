namespace kri.lib

import System

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
