namespace kri

import System.Collections.Generic
import OpenTK.Graphics.OpenGL

public class Material( ani.data.Player ):
	public final name	as string
	public final dict	= shade.par.Dict()
	public final unit	= List[of meta.AdUnit]()
	public final tech	= array[of shade.Bundle]( kri.Ant.Inst.techniques.Size )
	public final metaList = List[of meta.Advanced]()
	public Meta[str as string] as meta.Advanced:
		get: return metaList.Find({m| return m.Name == str})
	public def getData[of T(struct)](str as string) as meta.Data[of T]:
		return Meta[str] as meta.Data[of T]
	
	public def constructor(str as string):
		name = str
	private def clone[of T(System.ICloneable)](me as T) as T:
			return me.Clone() as T
	public def touch() as void:	#imp: IPlayer
		pass

	# clone with all 1-st level metas
	public def constructor(mat as Material):
		name = mat.name
		for u in mat.unit:
			unit.Add( clone(u) )
		for me in mat.metaList:
			metaList.Add( clone(me) )

	# update dictionary
	public def link() as void:
		dict.Clear()
		lis = List[of meta.IBase]()
		def push(h as meta.IBase):
			return if h in lis
			h.link(dict)
			lis.Add(h)
		for m in metaList:
			push(m)
			continue	if m.Unit<0
			u = unit[m.Unit]
			(u as meta.ISlave).link( m.Name, dict )
		for u in unit:
			push( u.input )
	
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
			ud = m.Unit
			continue	if ud<0
			u = unit[ud]
			push( u.input )
			din.Add( m.Name, u.input )
		# check geometry shaders
		if not geom:
			for dk in dd.Keys:
				if dk.type == ShaderType.GeometryShader:
					#dd.Remove(dk)
					return null
		# generate coords
		mapins = load.Meta.MakeTexCoords(geom,din)
		return null	if not mapins
		for sh in mapins:
			dd[sh] = null
		return dd.Keys
