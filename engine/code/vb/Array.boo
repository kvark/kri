namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Entry:
	public	final	buffer	as IBuffed
	public	final	info	as Info
	public	final	offset	as uint
	public	final	stride	as uint

	public	def constructor(vat as IProvider, name as string):
		buffer = null
		stride = offset = 0
		for ai in vat.Semant:
			if ai.name == name:
				buffer = vat
				info = ai
				offset = stride
			stride += ai.fullSize()
	
	public	def constructor(vat as IBuffed, ai as Info, off as uint, size as uint):
		buffer = vat
		info = ai
		offset,stride = off,size



#-----------------------
#	VERTEX ARRAY
#-----------------------

public class Array:
	public	static	final Default	= Array(0)
	public	static	Current	= Default
	public	final	handle	as uint
	[Getter(Empty)]
	private empty	as bool	= true
	
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
	
	public def push(slot as uint, at as Info, offset as uint, stride as uint) as void:
		empty = false
		GL.EnableVertexAttribArray( slot )
		if at.integer: #TODO: use proper enum
			GL.VertexAttribIPointer( slot, at.size,
				cast(VertexAttribIPointerType,cast(int,at.type)),
				stride, System.IntPtr(offset) )
		else:
			GL.VertexAttribPointer( slot, at.size,
				at.type, false, stride, offset)
	
	public def push(slot as uint, ref e as Entry) as void:
		e.buffer.Data.bind()
		push( slot, e.info, e.offset, e.stride )
	
	public def pushAll(sat as (kri.shade.Attrib), vat as IList[of kri.vb.Attrib]) as bool:
		empty = true
		bind()
		for i in range(sat.Length):
			if not sat[i].name:
				continue
			target as kri.vb.Info
			for at in vat:
				offset = stride = 0
				for sem in at.Semant:
					if sem.name == sat[i].name:
						target = sem
						offset = stride
					stride += sem.fullSize()
				if target.size:
					at.bind()
					break
			if not sat[i].matches(target):
				return false
			push(i,target,offset,stride)
		# need at least one
		if Empty:
			sem = vat[0].Semant[0]
			push(0,sem,0,0)
		return true
	
	public def pushAll(sat as (kri.shade.Attrib), edic as Dictionary[of string,Entry]) as bool:
		empty = true
		bind()
		for i in range(sat.Length):
			str = sat[i].name
			if not str:
				continue
			assert sat[i].size
			en as Entry
			if not edic.TryGetValue(str,en):
				return false
			ai = en.info
			if not sat[i].matches(ai):
				return false
			ai.name = str
			en.buffer.Data.bind()
			push( i, ai, en.offset, en.stride )
		# need at least one
		if Empty:
			for en in edic.Values:
				push(0,en)
				break
		assert not Empty
		return true
