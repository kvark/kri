namespace kri.kit.bake

import System
import OpenTK.Graphics.OpenGL


public class Tag(kri.ITag):
	public wid	as uint	= 0
	public het	as uint	= 0
	public vert	as bool = true
	public quat as bool = true
	public def pure() as bool:
		return wid*het == 0


#---------	RENDER VERTEX SPATIAL TO UV		--------#

public class Update( kri.rend.tech.Basic ):
	private final sa	= kri.shade.Smart()
	private final buf	= kri.frame.Buffer()
	public final bWorld	as bool
	public final size	as int
	public final units	= Array.ConvertAll(('vert','quat')) do(s as string):
		return kri.Ant.Inst.slotUnits.getForced('map_'+s)
	
	public def constructor(sord as int, world as bool):
		super('bake.mesh')
		size = sord
		sa.add( '/uv/bake_v' ,'/uv/bake_f' )
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	public override def process(con as kri.rend.Context) as void:
		con.DepTest = false
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			continue if not e.visible or not tag or tag.pure()
			n = (e.node if bWorld else null)
			kri.Ant.Inst.params.modelView.activate(n)
			buf.init(tag.wid, tag.het)
			a = kri.Ant.Inst.attribs
			if	not e.va[tid]:
				e.enable(tid, (a.vertex, a.quat, a.tex))
			else:	e.va[tid].bind()
			buf.mask = 0
			for i in range(units.Length):
				continue	if not (tag.vert,tag.quat)[i]
				u = e.unit[ units[i] ]
				if not u:	# no rectangles for now
					e.unit[ units[i] ] = buf.A[i].new( (32,8)[i], TextureTarget.Texture2D )
				else:	buf.A[i].Tex = u
				buf.mask |= 1<<i
			buf.activate()
			sa.use()
			e.mesh.draw()
