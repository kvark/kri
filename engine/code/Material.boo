namespace kri

import System.Collections.Generic


public class Material( ani.data.Player ):
	public final name	as string
	public final dict	= shade.rep.Dict()
	public final tech	= array[of shade.Smart]( lib.Const.nTech )
	public final metaList = List[of meta.Advanced]()
	public Meta[str as string] as meta.Advanced:
		get: return metaList.Find({m| return m.Name == str})
	
	public def constructor(str as string):
		name = str
	private def clone[of T(meta.IBase)](me as T) as T:
			return me.clone() as T
	public def touch() as void:	#imp: IPlayer
		pass

	# clone with all metas
	public def constructor(mat as Material):
		name = mat.name
		for me in mat.metaList:
			mad = clone(me) as meta.Advanced
			metaList.Add(mad)
		/*
		def genPred(str as string):
			return do(n as shade.par.INamed):
				return n.Name == str
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
			inputs.Add(inp)*/

	# update dictionary
	public def link() as void:
		dict.Clear()
		lis = List[of meta.IBase]()
		def push(h as meta.IBase):
			return if h in lis
			h.link(dict)
			lis.Add(h)
		ulis = List[of meta.AdUnit]()
		ulis.Add(null)
		for m in metaList:
			push(m)
			u = m.Unit
			continue	if u in ulis
			#push(u)
			(u as meta.ISlave).link( m.Name, dict )
			push(u.input)
	
	# collect shaders for meta data
	public def collect(melist as (string)) as shade.Object*:
		dd = Dictionary[of shade.Object,meta.IShaded]()
		def push(m as meta.IShaded):
			dd[m.Shader] = m	if m.Shader
		din = Dictionary[of string,meta.Hermit]()
		for str in melist:
			m = Meta[str]
			return null	if not m
			push(m)
			u = m.Unit
			continue	if not u
			push( u.input )
			din.Add( m.Name, u.input )
		for sh in load.Meta.MakeTexCoords(din):
			dd[sh] = null
		return dd.Keys
