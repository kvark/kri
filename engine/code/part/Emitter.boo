namespace kri.part

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------------------------------------#
#	PARTICLE EMITTER 					#
#---------------------------------------#

public enum TechState:
	Unknown
	Ready
	Invalid

public class Emitter:
	public	visible		as bool		= true
	public	obj			as kri.Entity	= null
	public	mat			as kri.Material	= null
	public	final owner	as Manager
	public	final name	as string
	public	final entries	= Dictionary[of string,kri.vb.Entry]()
	public	final techReady	= array[of TechState]( kri.Ant.Inst.techniques.Size )
	public	final mesh		= kri.Mesh( BeginMode.Points )
	public	onUpdate	as callable(kri.Entity) as bool	= null
	public	Ready as bool:
		get: return mesh.vbo.Count>0 and mesh.vbo[0].Ready

	public def constructor(pm as Manager, str as string):
		owner,name = pm,str
	public def constructor(pe as Emitter):
		visible	= pe.visible
		obj		= pe.obj
		mat		= pe.mat
		owner	= pe.owner
		name	= pe.name
	
	public def update() as bool:
		remapBuffers()
		return (not onUpdate) or onUpdate(obj)
	
	public def remapBuffers() as void:
		assert owner
		allKeys = List[of string](entries.Keys)
		for key in allKeys:
			val = entries[key]
			if val.data != owner.mesh.vbo[0]:
				continue
			val.data = mesh.vbo[0]
			entries[key] = val

	public def allocate() as void:
		assert owner
		owner.initMesh( mesh )
		entries.Clear()
		mesh.fillEntries(entries)
	
	public def draw(bu as kri.shade.Bundle, num as uint) as bool:
		if not bu or not update():
			return false
		return mesh.render( owner.va, bu, entries, num, null )
