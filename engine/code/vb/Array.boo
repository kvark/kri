namespace kri.vb

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Entry:
	public	final	buffer	as IBuffed
	public	divisor			as uint
	public	final	info	as Info
	public	final	offset	as uint
	public	final	stride	as uint
	
	public	final	static	Zero = Entry(null,Info(),0,0)

	public	def constructor(vat as IProvider, name as string):
		buffer = null
		divisor = stride = offset = 0
		for ai in vat.Semant:
			if ai.name == name:
				buffer = vat
				info = ai
				offset = stride
			stride += ai.fullSize()
	
	public	def constructor(vat as IBuffed, ai as Info, off as uint, size as uint):
		buffer = vat
		divisor = 0
		info = ai
		offset,stride = off,size



#-----------------------
#	VERTEX ARRAY
#-----------------------

public class Array:
	public	static	final Default	= Array(0)
	public	static	Current		= Default
	public	final	handle		as uint
	private final	slots		= array[of Entry]( kri.Ant.Inst.caps.vertexAttribs )
	private	useMask	as uint		= 0
	private index	as Object	= null
	
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
		useMask = 0
		if self == Current:
			return
		Current = self
		GL.BindVertexArray(handle)
	
	public def clean() as void:
		bind()
		for i in range(slots.Length):
			slots[i] = Entry.Zero
			GL.DisableVertexAttribArray(i)
	
	public def push(slot as uint, ref e as Entry) as void:
		if slots[slot] == e:
			return
		slots[slot] = e
		e.buffer.Data.bind()
		GL.EnableVertexAttribArray( slot )
		GL.VertexAttribDivisor( slot, e.divisor )
		if e.info.integer: #TODO: use proper enum
			GL.VertexAttribIPointer( slot, e.info.size,
				cast(VertexAttribIPointerType,cast(int,e.info.type)),
				e.stride, System.IntPtr(e.offset) )
		else:
			GL.VertexAttribPointer( slot, e.info.size,
				e.info.type, false, e.stride, e.offset)
	
	public def pushAll(ind as Object, sat as (kri.shade.Attrib), edic as Dictionary[of string,Entry]) as bool:
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
			push(i,en)
			useMask |= 1<<i
		# need at least one
		Object.Index = index = ind
		if not useMask:
			for en in edic.Values:
				push(0,en)
				break
		return useMask + edic.Count > 0

	public def hasConflicts() as byte:
		lx = List[of Object]()
		if index:	lx.Add(index)
		for i in range(slots.Length):
			buf = slots[i].buffer
			if buf and ((1<<i)&useMask):
				lx.Add( buf.Data )
		num = 0
		for bx in kri.TransFeedback.Cache:
			if bx and bx in lx:
				++num
		return num
