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
#[ext.spec.Class(int,single,Color4,Vector4,Quaternion)]
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
	private final p		as par.Unit
	public def constructor(id as int, pu as par.Unit):
		tun,p = id,pu
	def IBase.upload() as void:
		#can't cache as long as not tracking GL bind calls
		#return	if not p.update()
		p.Value.bind(tun)


# Standard uniform dictionary
public class Dict( SortedDictionary[of string,callable] ):
	# could be callable(int) of IBase here
	[ext.spec.MethodSubClass(Uniform, int,single,Color4,Vector4,Quaternion)]
	#[ext.spec.ForkMethodEx(Uniform, int,single,Color4,Vector4,Quaternion)]
	public def add[of T(struct)](name as string, iv as par.IBase[of T]) as void:
		Add(name) do(loc as int):
			return Uniform[of T](iv,loc)
	public def attach(dict as Dict) as void:
		for p in dict:
			Add(p.Key, p.Value)