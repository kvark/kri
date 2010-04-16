namespace kri.kit.bake

import OpenTK.Graphics.OpenGL

public class Tag( kri.ITag ):
	public world	as bool = true	# in world space
	public clear	as bool = true	# clear textures
	public texid	as byte = 0		# tex-coord channel
	public final wid	as uint	= 0
	public final het	as uint = 0
	public final tVert	as kri.Texture	= null
	public final tQuat	as kri.Texture	= null
	
	public def constructor(w as uint, h as uint, bv as byte, bq as byte, filt as bool):
		wid,het = w,h
		def genTex(bits as byte) as kri.Texture:
			return null	if not bits
			(t = kri.Texture( TextureTarget.Texture2D )).bind()
			fm = kri.Texture.AskFormat( kri.Texture.Class.Color, bits )
			kri.Texture.Init(w,h,fm)
			kri.Texture.Filter(filt,false)
			return t
		tVert,tQuat = genTex(bv),genTex(bq)


#---------	RENDER VERTEX SPATIAL TO UV		--------#

public class Update( kri.rend.tech.Basic ):
	private final sa	= kri.shade.Smart()
	private final buf	= kri.frame.Buffer()
	
	public def constructor():
		super('bake.mesh')
		sa.add( '/uv/bake_v' ,'/uv/bake_f', 'quat' )
		sa.fragout('re_vertex','re_quat')
		#sa.add( '/copy_v' ,'/uv/test_f' )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	public override def process(con as kri.rend.Context) as void:
		con.DepTest = false
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			a = kri.Ant.Inst.attribs
			continue if not e.visible or not tag or\
				not attribs(true, e, a.vertex,a.quat,a.tex[0])
			assert tag.texid == 0
			n = (e.node if tag.world else null)
			kri.Ant.Inst.params.modelView.activate(n)
			buf.init( tag.wid, tag.het )
			buf.mask = 0
			for i in range(2):
				buf.A[i].Tex = t = (tag.tVert,tag.tQuat)[i]
				continue	if not t
				buf.mask |= 1<<i
			buf.activate()
			con.ClearColor()	if tag.clear
			sa.use()
			q = kri.Query( QueryTarget.SamplesPassed )
			using q.catch():
				e.mesh.draw(1)
			assert q.result()
