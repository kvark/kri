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
	# META-2 version
	public final metaList = List[of meta.Advanced]()
	public Meta[str as string] as meta.Advanced:
		get: return metaList.Find({m| return m.Name == str})
		set:
			metaList.RemoveAll({m| return m.Name == str})
			value.Name = str
			metaList.Add(value)
	
	public def constructor(str as string):
		name = str
	public def constructor(m as Material):
		name = m.name
		for i in range(unit.Length):
			u = m.unit[i]
			continue	if not u
			unit[i] = kri.meta.Unit(u)
		for i in range(meta.Length):
			#warning! shared metas are not cloned
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
		# version: META-2
		nut = 0	# next unit index
		for m in metaList:
			m.link(dict)
			u = m.unit
			continue	if not u
			u.link(dict)
			u.input.link(dict)
			if dict.unit(u,nut): ++nut
		assert nut <= lib.Const.offUnit
			
	# set state (no need for META-2)
	public def apply() as void:
		for i in range( unit.Length ):
			u = unit[i]
			continue if not u or not u.tex
			Ant.Inst.units.Tex[i] = u.tex
	
	# collect for META-2
	public def collect(melist as (string)) as shade.Object*:
		# need caching here!
		sl = List[of shade.Object]()
		def push(h as shade.Object):
			return	if not h #or sl.Contains(h)
			sl.Add(h)
		u2h = Dictionary[of string,string]()
		for str in melist:
			m = Meta[str]
			return null	if not m
			push(m.shader)
			u = m.unit
			continue	if not u
			u2h[u.Name] = u.input.Name
			push(u.shader)
			push(u.input.shader)
		# store the TC dictionary outside material
		sl.Add( load.Meta.MakeTexCoords(u2h) )
		return sl

	# collect objects
	public def collect(un as (int), me as (int)) as shade.Object*:
		sl = List[of shade.Object]()
		def push(h as shade.Object):
			return	if not h #or sl.Contains(h)
			sl.Add(h)
		def addMeta(m as meta.Basic):
			push( m.shader )	if m
		for i in me:
			addMeta(meta[i])
		for i in un:
			u = unit[i]
			return null if not u
			addMeta( u.liMeta )
			push( u.generator )
			push( u.sampler )
		return sl
