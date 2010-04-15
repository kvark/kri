namespace kri

import System.Collections.Generic


public class Material( ani.data.Player ):
	public final name	as string
	public final dict	= shade.rep.Dict()
	public final tech	= array[of shade.Smart]( lib.Const.nTech )
	public final metaList = List[of meta.IAdvanced]()
	public Meta[str as string] as meta.IAdvanced:
		get: return metaList.Find({m| return m.Name == str})
	
	public def constructor(str as string):
		name = str
	private def clone[of T(meta.IBase)](me as T) as T:
			return me.clone() as T
	public def touch() as void:	#imp: IPlayer
		pass

	# clone with all metas
	public def constructor(mat as Material):
		def genPred(str as string):
			return do(n as shade.par.INamed):
				return n.Name == str
		name = mat.name
		units	= List[of meta.AdUnit]()
		inputs	= List[of meta.Hermit]()
		for me in mat.metaList:
			mad = clone(me) as meta.Advanced
			metaList.Add(mad)
			un = mad.Unit
			continue	if not un
			mad.Unit = units.Find( genPred(un.Name) )
			continue	if mad.Unit
			un = mad.Unit = clone(un)
			units.Add(un)
			inp = un.input
			un.input = inputs.Find( genPred(inp.Name) )
			continue	if un.input
			inp = un.input = clone(inp)
			inputs.Add(inp)

	# update dictionary
	public def link() as void:
		dict.Clear()
		lis = List[of meta.IBase]()
		def push(h as meta.IBase):
			return if h in lis
			h.link(dict)
			lis.Add(h)
		# unit name -> slot id
		ulis = List[of string]()
		for m in metaList:
			push(m)
			u = m.Unit
			continue	if not u
			push(u)
			push(u.input)
			if not u.Name in ulis:
				ulis.Add(u.Name)
			# passing as unit_{meta}
			dict.unit(m.Name,u)
	
	# collect shaders for meta data
	public def collect(melist as (string)) as shade.Object*:
		dd = Dictionary[of shade.Object,meta.IShaded]()
		def push(m as meta.IShaded):
			dd[m.Shader] = m	if m.Shader
		cl = List[of (string)]()
		for str in melist:
			m = Meta[str]
			return null	if not m
			push(m)
			u = m.Unit
			continue	if not u
			push( u.input )
			cl.Add(( m.Name, u.Name, u.input.Name ))
		dd[ load.Meta.MakeTexCoords(cl) ] = null
		return dd.Keys
