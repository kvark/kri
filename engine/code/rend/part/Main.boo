namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PARTICLES BASE		--------#

public class Basic( kri.rend.Basic ):
	public bAdd		as single = 0f
	protected def constructor():
		super(false)
	protected abstract def prepare(pe as kri.part.Emitter, ref nin as uint) as kri.shade.Program:
		pass
	public def drawScene() as void:
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd>0f:	blend.add()
			else:		blend.alpha()
			for pe in kri.Scene.Current.particles:
				nInst as uint = 0
				sa = prepare(pe,nInst)
				continue	if not sa
				pe.va.bind()
				return	if not pe.prepare()
				sa.use()
				pe.owner.draw(nInst)


#---------	RENDER PARTICLES: SINGLE SHADER		--------#

public abstract class Simple( Basic ):
	protected final sa		= kri.shade.Smart()
	public dTest	as bool	= true
	protected override def prepare(pe as kri.part.Emitter, ref nin as uint) as kri.shade.Program:
		return sa
	public override def process(con as kri.rend.Context) as void:
		off = (Single.NaN,0f)[dTest]
		con.activate( ColorTarget.Same, off, false )
		drawScene()
