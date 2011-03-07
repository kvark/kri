namespace kri.shade.rep

import System
import System.Collections.Generic

import OpenTK
import OpenTK.Graphics
import kri.shade

 
public class Base:
	public final loc	as int
	# uniform location
	protected def constructor(id as int):
		loc = id
	# send data to the shader
	public abstract def upload(iv as par.IBaseRoot) as void:
		pass
	# generate an uniform representor
	public static def Create(iv as par.IBaseRoot, loc as int) as Base:
		it = iv.GetType().GetInterface('IBase`1')
		T = it.GetGenericArguments()[0]
		assert T.IsValueType
		if T == int:
			return Uniform_int(loc)
		elif T == single:
			return Uniform_single(loc)
		elif T == Vector4:
			return Uniform_Vector4(loc)
		elif T == Quaternion:
			return Uniform_Quaternion(loc)
		elif T == Color4:
			return Uniform_Color4(loc)
		return null


# Uniform param representor
[ext.spec.Class(( int,single,Color4,Vector4,Quaternion ))]
public class Uniform[of T(struct)](Base):
	public data	as T
	public def constructor(lid as int):
		super(lid)
	public override def upload(iv as par.IBaseRoot) as void:
		val = (iv as par.IBase[of T]).Value
		if data != val:
			data = val
			Program.Param(loc,data)


# Texture Unit representor
public class Unit(Base):
	public final tun	as int
	public def constructor(lid as int,tid as int):
		super(lid)
		Program.Param(lid,tid)
		tun = tid
	public override def upload(iv as par.IBaseRoot) as void:
		if iv as par.IBase[of kri.Texture]:
			tex = (iv as par.IBase[of kri.Texture]).Value
			tex.bind(tun)	if tex
		else:
			t2 = (iv as par.IBase[of kri.buf.Texture]).Value
			if t2:
				kri.buf.Texture.Slot(tun)
				t2.bind()


# Standard uniform dictionary
public class Dict( SortedDictionary[of string,par.IBaseRoot] ):
	# copy contents of another dictionary
	public def attach(d as Dict) as void:
		for u in d:
			Item[u.Key] = u.Value
	# add standard uniform
	public def var[of T](*var as (par.Value[of T])) as void:
		for v in var:
			Item[v.Name] = v
	# add custom unit
	public def unit(name as string, v as par.IBase[of kri.Texture]) as void:
		Item[Smart.prefixUnit + name] = v
	# add texture unit representor
	public def unit(*vat as (par.Value[of kri.Texture])) as void:
		for v in vat:
			unit(v.Name,v)
	public def unitNew(*vat as (par.Value[of kri.buf.Texture])) as void:
		for v in vat:
			Item[Smart.prefixUnit + v.Name] = v
