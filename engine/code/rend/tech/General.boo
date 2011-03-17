namespace kri.rend.tech

import System.Collections.Generic


#--------- Batch ---------#

public struct Batch:	# why struct?
	public e	as kri.Entity
	public va	as kri.vb.Array
	public bu	as kri.shade.Bundle
	public up	as callable() as int
	public off	as int
	public num	as int

	public def draw() as void:
		nob = up()
		kri.Ant.Inst.params.modelView.activate( e.node )
		e.mesh.render(va,bu,null, off,num,nob)
		
	#public static cMat	= CompMat()
	public class CompMat( IComparer[of Batch] ):
		public def Compare(a as Batch, b as Batch) as int:
			r = a.bu.shader.handle - b.bu.shader.handle
			return r	if r
			r = a.va.handle - b.va.handle
			return r

	public static cMat	as IComparer[of Batch]	= CompMat()


#---------	GENERAL TECHNIQUE	--------#

public class General( Basic ):
	public static comparer	as IComparer[of Batch]	= null
	protected final butch	= List[of Batch]()
	
	public struct Updater:
		public final fun	as callable() as int
		public def constructor(f as callable() as int):
			fun = f

	protected def constructor(name as string):
		super(name)
	public abstract def construct(mat as kri.Material) as kri.shade.Bundle:
		pass
	protected virtual def getUpdater(mat as kri.Material) as Updater:
		return Updater() do() as int:
			return 1

	protected def addObject(e as kri.Entity) as void:
		return	if not e.visible
		#alist as List[of int] = null
		tempList = List[of Batch]()
		atList	as List[of kri.shade.Attrib]	= null
		if e.va[tid] == kri.vb.Array.Default:
			return
		elif not e.va[tid]:
			(e.va[tid] = kri.vb.Array()).bind()
			atList = List[of kri.shade.Attrib]()
			if e.mesh:
				e.mesh.ind.bind()
		b = Batch(e:e, va:e.va[tid], off:0)
		for tag in e.enuTags[of kri.TagMat]():
			m = tag.mat
			b.num = tag.num
			b.off = tag.off
			prog = m.tech[tid]
			if not prog:
				m.tech[tid] = prog = construct(m)
			if prog == kri.shade.Bundle.Empty:
				continue
			if atList:
				atList.AddRange( prog.shader.attribs )
			b.bu = prog
			b.up = getUpdater(m).fun
			tempList.Add(b)
		if atList and not b.va.pushAll( atList.ToArray(), e.CombinedAttribs ):
			e.va[tid] = kri.vb.Array.Default
		else: butch.AddRange(tempList)


	# shouldn't be used as some objects have to be excluded
	protected def drawScene() as void:
		butch.Clear()
		for e in kri.Scene.Current.entities:
			addObject(e)
		if comparer:
			butch.Sort(comparer)
		for b in butch:
			b.draw()
