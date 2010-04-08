namespace kri.kit.bake

import OpenTK.Graphics.OpenGL

public class Tag( kri.ITag ):
	public world	as bool = true	# in world space
	public clear	as bool = true	# clear textures
	public texid	as byte = 0		# tex-coord channel
	public final tVert	as kri.Texture	= null
	public final tQuat	as kri.Texture	= null
	
	public def constructor(wid as uint, het as uint, bv as byte, bq as byte):
		def genTex(bits as byte) as kri.Texture:
			return null	if not bits
			(t = kri.Texture( TextureTarget.Texture2D )).bind()
			fm = kri.Texture.AskFormat( kri.Texture.Class.Color, bv )
			kri.Texture.Init( wid,het, fm)
			return t
		tVert,tQuat = genTex(bv),genTex(bq)


#---------	RENDER VERTEX SPATIAL TO UV		--------#

public class Update( kri.rend.tech.Basic ):
	private final sa	= kri.shade.Smart()
	private final buf	= kri.frame.Buffer()
	
	public def constructor():
		super('bake.mesh')
		sa.add( '/uv/bake_v' ,'/uv/bake_f', 'quat' )
		#sa.add( '/copy_v' ,'/uv/test_f' )
		sa.fragout('re_vertex','re_quat')
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	public override def process(con as kri.rend.Context) as void:
		con.DepTest = false
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			a = kri.Ant.Inst.attribs
			continue if not e.visible or not tag or\
				not attribs(e, a.vertex, a.quat, a.tex[0])
			assert tag.texid == 0
			n = (e.node if tag.world else null)
			kri.Ant.Inst.params.modelView.activate(n)
			buf.mask = 0
			for i in range(2):
				buf.A[i].Tex = t = (tag.tVert,tag.tQuat)[i]
				continue	if not t
				buf.mask |= 1<<i
			buf.activate()
			con.ClearColor()	if tag.clear
			sa.use()
			e.mesh.draw()
			kri.Ant.Inst.emitQuad()
