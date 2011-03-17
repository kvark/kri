namespace kri.vb

#import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#-----------------------
#	VERTEX ARRAY
#-----------------------

public class Array:
	public	static	final Default	= Array(0)
	public	static	Current	= Default
	public	final	handle	as uint
	
	public def constructor():
		tmp = 0
		GL.GenVertexArrays(1,tmp)
		handle = tmp
	private def constructor(xid as uint):
		handle = xid
	def destructor():
		tmp = handle
		kri.Help.safeKill() do():
			GL.DeleteVertexArrays(1,tmp)
	
	public def bind() as void:
		if self == Current:
			return
		Current = self
		GL.BindVertexArray(handle)
	
	public def clean() as void:
		bind()
		for i in range(kri.Ant.Inst.caps.vertexAttribs):
			GL.DisableVertexAttribArray(i)
	
	public def push(slot as uint, ref at as Info, off as int, total as int) as void:
		GL.EnableVertexAttribArray( slot )
		if at.integer: #TODO: use proper enum
			GL.VertexAttribIPointer( slot, at.size,
				cast(VertexAttribIPointerType,cast(int,at.type)),
				total, System.IntPtr(off) )
		else:
			GL.VertexAttribPointer( slot, at.size,
				at.type, false, total, off)
	
	public def pushAll(sat as (kri.shade.Attrib), vat as IList[of kri.vb.Attrib]) as int:
		bind()
		names = List[of string]()
		for cur in sat:
			assert cur.name and cur.size
			if cur.name in names:
				continue
			target as kri.vb.Info
			for at in vat:
				off = total = 0
				for sem in at.Semant:
					if sem.name == cur.name:
						target = sem
						off = total
					total += sem.fullSize()
				if target.size:
					at.bind()
					break
			if not cur.matches(target):
				return -1
			push( names.Count, target, off, total )
			names.Add( cur.name )
		# need at least one
		if not sat.Length:
			sem = vat[0].Semant[0]
			push(0,sem,0,0)
		return names.Count
