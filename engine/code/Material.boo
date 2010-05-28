namespace kri

import System.Collections.Generic
import OpenTK.Graphics.OpenGL

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

	# clone with all 1-st level metas
	public def constructor(mat as Material):
		name = mat.name
		for me in mat.metaList:
			mad = clone(me) as meta.Advanced
			metaList.Add(mad)

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
	public def collect(geom as bool, melist as (string)) as shade.Object*:
		dd = Dictionary[of shade.Object,meta.IShaded]()
		def push(m as meta.IShaded):
			dd[m.Shader] = m	if m.Shader
		# collect mets shaders & map inputs
		din = Dictionary[of string,meta.Hermit]()
		for str in melist:
			m = Meta[str]
			return null	if not m
			push(m)
			u = m.Unit
			continue	if not u
			push( u.input )
			din.Add( m.Name, u.input )
		# check geometry shaders
		if not geom:
			kar = array( dd.Keys )
			for dk in kar:
				if dk.type == ShaderType.GeometryShader:
					#dd.Remove(dk)
					return null
		# generate coords
		mapins = load.Meta.MakeTexCoords(geom,din)
		return null	if not mapins
		for sh in mapins:
			dd[sh] = null
		return dd.Keys
