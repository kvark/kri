namespace kri.rend.tech

#---------	GENERAL TECHNIQUE	--------#

public class General( Basic ):
	protected def constructor(name as string):
		super(name)
	
	public abstract def construct(mat as kri.Material) as kri.shade.Bundle:
		pass
	protected abstract def onPass(va as kri.vb.Array, tm as kri.TagMat, bu as kri.shade.Bundle) as void:
		pass

	public virtual def addObject(e as kri.Entity) as bool:
		if not e.visible:
			return false
		atar	as (kri.shade.Attrib)	= null
		vao		as kri.vb.Array			= null
		if not e.va.TryGetValue(name,vao):
			e.va[name] = vao = kri.vb.Array()
			atar = array[of kri.shade.Attrib]( kri.Ant.Inst.caps.vertexAttribs )
		if vao == kri.vb.Array.Default:
			return false
		for tag in e.enuTags[of kri.TagMat]():
			m = tag.mat
			if not m:	continue
			prog as kri.shade.Bundle = null
			if not m.tech.TryGetValue(name,prog):
				m.tech[name] = prog = construct(m)
				if prog.shader and not prog.shader.Ready:
					# force attribute order
					prog.shader.attribAll( e.mesh.gatherAttribs() )
					prog.link()
			if prog.LinkFail:	continue
			if atar:	# merge attribs
				ats = prog.shader.attribs
				for i in range(atar.Length):
					if atar[i].name == ats[i].name:
						continue
					assert not atar[i].name
					atar[i] = ats[i]
			onPass(vao,tag,prog)
		if atar and not vao.pushAll( e.mesh.ind, atar, e.CombinedAttribs ):
			e.va[name] = kri.vb.Array.Default
			return false
		return true

