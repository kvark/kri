namespace support.bake

import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


public class Tag( kri.ITag ):
	public world	as bool = true	# in world space
	public clear	as bool = true	# clear textures
	public texid	as byte = 0		# tex-coord channel
	public final buf	= kri.frame.Buffer(0, TextureTarget.Texture2D )
	
	public Size as uint:
		get: return buf.Width * buf.Height * sizeof(single) *4
	public Vert as kri.Texture:
		get: return buf.A[0].Tex
	public Quat as kri.Texture:
		get: return buf.A[1].Tex
	
	public def constructor(w as uint, h as uint, bv as byte, bq as byte, filt as bool):
		buf.init(w,h)
		buf.mask = 0
		for i in range(2):
			bits = (bv,bq)[i]
			continue	if not bits
			buf.mask |= 1<<i
			buf.emitAuto(i,bits).bind()
			kri.Texture.Filter(filt,false)


#---------	RENDER VERTEX SPATIAL TO UV		--------#

public class Update( kri.rend.tech.Basic ):
	private final sa	= kri.shade.Smart()
	
	public def constructor():
		super('bake.mesh')
		sa.add( '/uv/bake_v' ,'/uv/bake_f', '/lib/quat_v' )
		sa.fragout('re_vertex','re_quat')
		#sa.add( '/copy_v' ,'/uv/test_f' )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	public override def process(con as kri.rend.Context) as void:
		con.DepthTest = false
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			a = kri.Ant.Inst.attribs
			continue if not e.visible or not tag or\
				not attribs(true, e, a.vertex,a.quat,a.tex[0])
			assert tag.texid == 0
			n = (e.node if tag.world else null)
			kri.Ant.Inst.params.modelView.activate(n)
			tag.buf.activate()
			# todo: clear only on init
			con.ClearColor( Color4(0f,0f,0f,0f) )	if tag.clear
			sa.use()
			q = kri.Query( QueryTarget.SamplesPassed )
			using q.catch():
				e.mesh.draw(1)
			assert q.result()
