namespace kri.rend.tech

import System.Collections.Generic

public interface IConstructor:
	def construct(mat as kri.Material) as kri.shade.Smart


#--------- Batch ---------#

public struct Batch:	# why struct?
	public e	as kri.Entity
	public va	as kri.vb.Array
	public sa	as kri.shade.Smart
	public up	as callable() as int
	public off	as int
	public num	as int

	public def draw() as void:
		nob = up()
		kri.Ant.Inst.params.modelView.activate( e.node )
		va.bind()
		sa.use()
		e.mesh.draw(off,num,nob)
		
	public class CompMat( IComparer[of Batch] ):
		public def Compare(a as Batch, b as Batch) as int:
			r = a.sa.id - b.sa.id
			return r	if r
			r = a.va.id - b.va.id
			return r
	public static cMat	= CompMat()


#---------	GENERAL TECHNIQUE	--------#

public class General( IConstructor, Basic ):
	public static comparer	as IComparer[of Batch]	= null
	protected	final butch	= List[of Batch]()
	protected def constructor(name as string):
		super(name)
	public abstract def construct(mat as kri.Material) as kri.shade.Smart:
		pass
	protected virtual def getUpdate(mat as kri.Material) as callable() as int:
		return def() as int: return 1

	protected def addObject(e as kri.Entity) as void:
		return	if not e.visible
		#alist as List[of int] = null
		if e.va[tid] == kri.vb.Array.Default: return
		elif not e.va[tid]:
			(e.va[tid] = kri.vb.Array()).bind()
			alist = List[of int]()
		b = Batch(e:e, va:e.va[tid], off:0)
		tempList = List[of Batch]()
		for tag in e.tags:
			tm = tag as kri.TagMat
			continue	if not tm
			m = tm.mat
			b.num = tm.num
			b.off = tm.off
			prog = m.tech[tid]
			if not prog:
				m.tech[tid] = prog = construct(m)
			continue	if prog == kri.shade.Smart.Fixed
			if alist:
				ids = prog.gatherAttribs( kri.Ant.Inst.slotAttributes )
				alist.AddRange(a	for a in ids	if not a in alist)
			b.sa = prog
			b.up = getUpdate(m)
			tempList.Add(b)
		if alist and not e.enable(true,alist):
			e.va[tid] = kri.vb.Array.Default
		else:	butch.AddRange(tempList)

	# shouldn't be used as some objects have to be excluded
	protected def drawScene() as void:
		butch.Clear()
		for e in kri.Scene.Current.entities:
			addObject(e)
		butch.Sort(comparer)	if comparer
		for b in butch:
			b.draw()