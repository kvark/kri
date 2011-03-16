namespace kri.part

import System
import System.Collections.Generic


# interleaved attribute array holder
public class DataHolder( kri.vb.ISource ):
	[Getter(Data)]
	public data		as kri.vb.Attrib	= null
	public va		= kri.vb.Array()
	public def init(sem as kri.vb.Info*, num as uint) as void:
		if data:	data.Semant.Clear()
		else:		data = kri.vb.Attrib()
		data.Semant.AddRange( sem )
		va.bind()
		assert not 'supported'	# initAll?
		#data.initAll( num )

# external particle attribute
public struct ExtAttrib:
	public dest		as string
	public source	as string
	public vat		as kri.vb.ISource


#---------------------------------------#
#	PARTICLE EMITTER 					#
#---------------------------------------#

public enum TechState:
	Unknown
	Ready
	Invalid

public class Emitter(DataHolder):
	public visible	as bool		= true
	public onUpdate	as callable(kri.Entity) as bool	= null
	public obj		as kri.Entity	= null
	public mat		as kri.Material	= null
	public final owner	as Manager
	public final name	as string
	public final extList	= List[of ExtAttrib]()
	public final techReady	= array[of TechState]( kri.Ant.Inst.techniques.Size )

	public def constructor(pm as Manager, str as string):
		owner,name = pm,str
	public def constructor(pe as Emitter):
		visible	= pe.visible
		obj		= pe.obj
		mat		= pe.mat
		owner	= pe.owner
		name	= pe.name

	public def allocate() as void:
		assert owner
		init( owner.data.Semant, owner.total )

	public def prepare() as bool:
		if onUpdate and not onUpdate(obj):
			return false
		loadFake()
		return true

	private def loadFake()	as void:	#todo: redo
		d = Dictionary[of string,string]()
		for fa in extList:
			vat = fa.vat.Data
			assert vat
			if fa.source:
				d.Clear()
				d[fa.source] = fa.dest
			#	vat.attribTrans(d)
			#else: vat.attrib( fa.dest )

	public def listAttribs() as (string):
		return	List[of string](sem.name	for sem in data.Semant).ToArray() +\
				List[of string](ext.dest	for ext in extList).ToArray()
