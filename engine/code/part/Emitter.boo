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
		return (not onUpdate) or onUpdate(obj)

	public def allocate() as void:
		assert owner
		owner.initMesh( mesh )
		entries.Clear()
		mesh.fillEntries(entries)

/*	private def loadFake()	as void:	#todo: redo
		assert not 'ready'
		d = Dictionary[of string,string]()
		for fa in extList:
			vat = fa.vat.Data
			assert vat
			if fa.source:
				d.Clear()
				d[fa.source] = fa.dest
			#	vat.attribTrans(d)
			#else: vat.attrib( fa.dest )*/

	public def listAttribs() as (string):
		assert not 'supported'
		return	List[of string](sem.name	for sem in mesh.vbo[0].Semant).ToArray()# +
				#List[of string](sem.name	for sem in vbo for vbo in extMesh).ToArray()
