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
		lis = List[of meta.IBase]()
		def push(h as meta.IBase):
			return if h in lis
			h.link(dict)
			lis.Add(h)
		# unit name -> slot id
		uDic = Dictionary[of string,int]()
		for m in metaList:
			push(m)
			u = m.unit
			continue	if not u
			push(u)
			push(u.input)
			nut = 0
			if not uDic.TryGetValue(u.Name,nut):
				nut = uDic.Count
				uDic.Add(u.Name,nut)
			assert nut <= lib.Const.offUnit
			# passing as unit_{meta}
			dict.unit(u, m.Name, nut)
			
	# set state (no need for META-2)
	public def apply() as void:
		for i in range( unit.Length ):
			u = unit[i]
			continue if not u or not u.tex
			Ant.Inst.units.Tex[i] = u.tex
	
	# collect for META-2
	public def collect(melist as (string)) as shade.Object*:
		dd = Dictionary[of shade.Object,meta.Hermit]()
		def push(m as meta.Hermit):
			dd[m.shader] = m	if m.shader
		cl = List[of string]()
		for str in melist:
			m = Meta[str]
			return null	if not m
			push(m)
			u = m.unit
			continue	if not u
			push(u.input)
			cl.Add( "${m.Name},${u.Name},${u.input.Name}" )
		dd[ load.Meta.MakeTexCoords(cl) ] = null
		return dd.Keys

	# collect objects (DEPRECATED)
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
