namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL

#---------	RENDER PARTICLES		--------#

public class Basic( kri.rend.Basic ):
	public final dTest	as bool
	public final bAdd	as bool
	public def constructor(depth as bool, add as bool):
		super(false)
		dTest,bAdd = depth,add
	public def draw(pe as kri.part.Emitter) as void:
		# assemble the shader from material's meta data
		pe.draw()
	public override def process(con as kri.rend.Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			lis = List[of kri.part.Emitter]( kri.Scene.Current.particles )
			while lis.Count:
				man = lis[0].man
				pred = {p as kri.part.Emitter| return p.man == man }
				for pe in lis.FindAll(pred):
					draw(pe)
				lis.RemoveAll(pred)
