namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public interface ISource:
	Data	as Attrib:
		get


#---------

public struct Info:
	public slot	as int	# from slotAttributes
	public size	as int	# in units
	public type	as VertexAttribPointerType
	public integer	as bool
	public def fullSize() as int:
		b = 0
		b = 1	if type == VertexAttribPointerType.UnsignedByte
		b = 2	if type == VertexAttribPointerType.HalfFloat
		b = 2	if type == VertexAttribPointerType.UnsignedShort
		b = 4	if type == VertexAttribPointerType.Float
		b = 4	if type == VertexAttribPointerType.UnsignedInt
		assert b and 'not a valid type'
		return size * b


#---------

public class Storage:
	public final vbo = List[of kri.vb.Attrib]()
	public def find(id as int) as kri.vb.Attrib:
		return vbo.Find() do(v as kri.vb.Attrib):
			s = v.Semant
			return s.Count>0 and s[0].slot==id
	public def bind(id as int) as bool:
		return vbo.Exists() do(v as kri.vb.Attrib):
			return v.attrib(id)
	public def swap(x as kri.vb.Attrib, y as kri.vb.Attrib) as void:
		#vbo.Remove(x)
		#vbo.Add(y)
		vbo[ vbo.IndexOf(x) ] = y
