namespace kri.lib

import System


# Constant Storage
public static class Const:
	public final nTech		= 24	# Render Techniques
	public final nUnit		= 16	# Map Units
	public final offUnit	= 8		# TexUnit offset
	public final nAttrib	= 16	# Vertex Attributes
	public final nMeta		= 32	# Meta Parameters
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
		id = Array.FindIndex(lib) do(s as string):
			return s is null
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
	public def getForced(name as string) as int:
		id = find(name)
		return (id if id>=0 else create(name))


# Texture Units Library
public final class Unit:
	private final par	= array[of kri.shade.par.Unit]( Const.nUnit )
	public Par[id as int] as kri.shade.par.Unit:
		get: return par[id];
	public Tex[id as int] as kri.Texture:
		get: return par[id].Value
		set: par[id].Value = value

	public final input		as int	# quad input
	public final depth		as int	# depth buffer
	public final light		as int	# light depth
	public final texture	as int	# texture
	public final bump		as int	# bump
	public final reflect	as int	# reflection

	internal def constructor(s as Slot):
		for i in range( Const.nUnit ):
			par[i] = kri.shade.par.Unit()
		input	= s.getForced('input')
		depth	= s.getForced('depth')
		light	= s.getForced('light')
		texture	= s.getForced('texture')
		bump	= s.getForced('bump')
		reflect	= s.getForced('reflect')
		
	public def activate(tu as (kri.Texture)) as void:
		for i in range( Const.nUnit ):
			Tex[i] = tu[i]	if tu[i]


public final class Attrib:
	public final vertex		as int
	public final quat		as int
	public final skin		as int
	public final tex		= (of int: 0,0,0,0)
	internal def constructor(s as Slot):
		vertex	= s.getForced('vertex')
		quat	= s.getForced('quat')
		skin	= s.getForced('skin')
		for i in range(tex.Length):
			tex[i]	= s.getForced('tex'+i)
