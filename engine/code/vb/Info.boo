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

	public def gatherAttribs() as (string):
		al = List[of string]()
		for vat in vbo:
			for ai in vat.Semant:
				al.Add( ai.name )
		return al.ToArray()
	
	public def fillEntries(d as Dictionary[of string,Entry]) as void:
		for vat in vbo:
			e = Entry( data:vat, offset:0, stride:vat.unitSize() )
			for sem in vat.Semant:
				e.info = sem
				d[sem.name] = e
				e.offset += sem.fullSize()
