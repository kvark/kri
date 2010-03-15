namespace kri

import System
import System.Collections.Generic


public interface IApplyable:
	def apply() as void

#---------

public class Material(IApplyable):
	public final name	as string
	public def constructor(str as string):
		name = str
	public final tech = array[of shade.Smart]	( lib.Const.nTech )
	public final unit = array[of meta.Unit]		( lib.Const.nUnit )
	public final meta = array[of meta.Basic]	( lib.Const.nMeta )
	# set state
	public def apply() as void:
		for m in meta:
			m.apply()	if m
		for i in range( lib.Const.nUnit ):
			Ant.Inst.units.Tex[i] = unit[i].tex	if unit[i] and unit[i].tex
	# collect objects
	public def collect(un as (int), me as (int)) as shade.Object*:
		sl = List[of shade.Object]()
		def push(h as shade.Object):
			return	if not h #or sl.Contains(h)
			sl.Add(h)
		for i in me:
			m = meta[i]
			return null	if not m
			push( m.shader )
		for i in un:
			u = unit[i]
			return null if not u
			push( u.generator )
			push( u.sampler )
		return sl
