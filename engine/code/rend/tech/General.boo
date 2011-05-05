namespace kri.rend.tech

import System.Collections.Generic


#--------- Batch ---------#

public struct Batch:	# why struct?
	public final	e		as kri.Entity
	public final	va		as kri.vb.Array
	public final	dict	as kri.vb.Dict
	public bu	as kri.shade.Bundle
	public up	as callable() as int
	public off	as int
	public num	as int
	
	public def constructor(ent as kri.Entity, vao as kri.vb.Array):
		e = ent
		va = vao
		dict = e.CombinedAttribs
		off = num = 0

	public def draw() as void:
		nob = up()
		kri.Ant.Inst.params.activate(e)
		e.mesh.render(va,bu,dict,off,num,nob,null)
		
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
	public	static	comparer	as IComparer[of Batch]	= null
	public	final	extraDict	= kri.vb.Dict()
	public	final	butch		= List[of Batch]()
	
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

	public def addObject(e as kri.Entity) as void:
		if not e.visible:
			return
		tempList = List[of Batch]()
		atar	as (kri.shade.Attrib)	= null
		vao as kri.vb.Array = null
		if not e.va.TryGetValue(name,vao):
			e.va[name] = vao = kri.vb.Array()
			atar = array[of kri.shade.Attrib]( kri.Ant.Inst.caps.vertexAttribs )
		if vao == kri.vb.Array.Default:
			return
		b = Batch(e,vao)
		for de in extraDict:
			b.dict.Add( de.Key, de.Value )
		for tag in e.enuTags[of kri.TagMat]():
			m = tag.mat
			if not m:	continue
			b.num = tag.num
			b.off = tag.off
			prog as kri.shade.Bundle = null
			if not m.tech.TryGetValue(name,prog):
				m.tech[name] = prog = construct(m)
				if prog.shader and not prog.shader.Ready:
					# force attribute order
					prog.shader.attribAll( e.mesh.gatherAttribs() )
					prog.link()
			if prog == kri.shade.Bundle.Empty:
				continue
			if atar:	# merge attribs
				ats = prog.shader.attribs
				for i in range(atar.Length):
					if atar[i].name == ats[i].name:
						continue
					assert not atar[i].name
					atar[i] = ats[i]
			b.bu = prog
			b.up = getUpdater(m).fun
			tempList.Add(b)
		if atar:
			if not b.va.pushAll( e.mesh.ind, atar, e.CombinedAttribs ):
				e.va[name] = kri.vb.Array.Default
				return
		butch.AddRange(tempList)


	# shouldn't be used as some objects have to be excluded
	protected def drawScene() as void:
		scene = kri.Scene.Current
		if not scene:
			return
		butch.Clear()
		for e in scene.entities:
			addObject(e)
		if comparer:
			butch.Sort(comparer)
		for b in butch:
			b.draw()
