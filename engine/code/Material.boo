namespace kri

import System.Collections.Generic


public interface IApplyable:
	def apply() as void

#---------

public class Material( IApplyable, ani.data.Player ):
	public final name	as string
	public final dict	= shade.rep.Dict()
	public final tech = array[of shade.Smart]	( lib.Const.nTech )
	public final unit = array[of meta.Unit]		( lib.Const.nUnit )
	public final meta = array[of meta.Basic]	( lib.Const.nMeta )
	
	public def constructor(str as string):
		name = str
	public def constructor(m as Material):
		name = m.name
		for i in range(unit.Length):
			u = m.unit[i]
			continue	if not u
			unit[i] = kri.meta.Unit(u)
		for i in range(meta.Length):
			b = m.meta[i]
			continue	if not b
			meta[i] = b.clone()
			meta[i].link(dict)

	# update dictionary
	public def link() as void:
		dict.Clear()
		for i in range( unit.Length ):
			str = Ant.Inst.slotUnits.Name[i]
			unit[i].link(dict,str)	if unit[i]
		for m in meta:
			m.link(dict)	if m
	# set state
	public def apply() as void:
		for i in range( unit.Length ):
			u = unit[i]
			continue if not u or not u.tex
			Ant.Inst.units.Tex[i] = u.tex

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
