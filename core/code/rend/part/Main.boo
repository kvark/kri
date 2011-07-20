﻿namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PARTICLES BASE		--------#

public class Basic( kri.rend.Basic ):
	public bAdd		as single = 0f 
	protected abstract def prepare(pe as kri.part.Emitter, ref nin as uint) as kri.shade.Bundle:
		pass
	public def drawScene() as void:
		scene = kri.Scene.Current
		if not scene:	return
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd>0f:	blend.add()
			else:		blend.alpha()
			for pe in scene.particles:
				if not (pe.visible and pe.filled):
					continue
				nInst as uint = 1
				bu = prepare(pe,nInst)
				pe.draw(bu,nInst)


#---------	RENDER PARTICLES: SINGLE SHADER		--------#

public abstract class Simple( Basic ):
	protected final bu		= kri.shade.Bundle()
	public dTest	as bool	= true
	protected override def prepare(pe as kri.part.Emitter, ref nin as uint) as kri.shade.Bundle:
		return bu
	public override def process(con as kri.rend.link.Basic) as void:
		off = (Single.NaN,0f)[dTest]
		con.activate( con.Target.Same, off, false )
		drawScene()