namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PARTICLES BASE		--------#

public class Basic( kri.rend.Basic ):
	public bAdd		as bool = false
	protected def constructor():
		super(false)
	protected abstract def prepare(pe as kri.part.Emitter) as kri.shade.Program:
		pass
	public def drawScene() as void:
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			for pe in kri.Scene.Current.particles:
				sa = prepare(pe)
				continue	if not sa
				pe.va.bind()
				return	if not pe.prepare()
				sa.use()
				pe.owner.draw()


#---------	RENDER PARTICLES: SINGLE SHADER		--------#

public class Simple( Basic ):
	protected final sa		= kri.shade.Smart()
	public dTest	as bool	= true
	protected override def prepare(pe as kri.part.Emitter) as kri.shade.Program:
		return sa
	public override def process(con as kri.rend.Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		drawScene()
