namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Info:
	public name	as string
	public size	as byte		# in units
	public type	as VertexAttribPointerType
	public integer	as bool
	public def fullSize() as uint:
		b as uint = 0
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
	public final static	Empty	= Storage()
	
	public def find(name as string) as kri.vb.Attrib:
		return vbo.Find() do(v as kri.vb.Attrib):
			s = v.Semant
			return s.Count>0 and s[0].name==name
	private def bind(name as string) as bool:	#todo: remove
		return vbo.Exists() do(v as kri.vb.Attrib):
			return true
			#return v.attrib(name)
	public def swap(x as kri.vb.Attrib, y as kri.vb.Attrib) as void:
		#vbo.Remove(x)
		#vbo.Add(y)
		vbo[ vbo.IndexOf(x) ] = y
