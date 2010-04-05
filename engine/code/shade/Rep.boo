namespace kri.shade.rep

import System
import System.Collections.Generic

import OpenTK
import OpenTK.Graphics
import kri.shade

#TODO: use simple extension blocks here

public interface IBase:
	# send data to the shader
	def upload() as void

# Uniform param representor (per shader)
[ext.spec.Class(int,single,Color4,Vector4,Quaternion)]
public class Uniform[of T(struct)]( par.Cached[of T], IBase ):
	private final loc as int
	public def constructor(p as par.IBase[of T], newloc as int):
		super(p)
		loc = newloc
	def IBase.upload() as void:
		return if not update()
		Program.Param(loc,cached)
		

# Texture Unit representor
public class Unit(IBase):
	private final tun	as int
	private final p		as par.IBase[of kri.Texture]
	public def constructor(id as int, pu as par.IBase[of kri.Texture]):
		tun,p = id,pu
	def IBase.upload() as void:
		p.Value.bind(tun)	if p.Value


# Standard uniform dictionary
public class Dict:
	private final sd	= SortedDictionary[of string,callable(int) as IBase]()
	
	# add standard uniform
	[ext.spec.ForkMethodEx(Uniform, int,single,Color4,Vector4,Quaternion)]
	public def add[of T(struct)](name as string, iv as par.IBase[of T]) as void:
		sd.Add(name) do(loc as int):
			return Uniform[of T](iv,loc)
	
	# add texture unit representor
	public def unit[of T(par.INamed,par.IBase[of kri.Texture])](it as T, tun as int) as bool:
		return unit(it as par.IBase[of kri.Texture], it.Name, tun)
	public def unit(*its as (par.Texture)) as bool:
		return Array.TrueForAll(its) do(it as par.Texture):
			return unit(it, it.Name, it.tun)
	public def unit(it as par.IBase[of kri.Texture], name as string, tun as int) as bool:
		name = kri.shade.Smart.prefixUnit + name
		return false	if sd.ContainsKey(name)
		sd.Add(name) do(loc as int):
			OpenGL.GL.Uniform1(loc,tun)
			return Unit(tun,it)
		return true
	
	# resolve value by name & location
	public def resolve(name as string, loc as int) as IBase:
		fun as callable(int) as IBase = null
		sd.TryGetValue(name,fun)
		return (fun(loc) if fun else null)
	
	# copy contents of another dictionary
	public def attach(dict as Dict) as void:
		for p in dict.sd:
			sd.Add(p.Key, p.Value)
	# clear contents
	public def clear() as void:
		sd.Clear()
