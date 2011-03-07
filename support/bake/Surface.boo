namespace support.bake.surf

import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


public class Tag( kri.ITag ):
	public worldSpace	as bool = true		# in world space
	public clearTarget	as bool = true		# clear textures
	public uvChannel	as byte = 0			# tex-coord channel
	public stamp		as double	= -1f	# last update
	public final buf	= kri.frame.Buffer(0, TextureTarget.Texture2D )
	public final allowFilter	as bool		# allow results filtering
	
	public Size as uint:
		get: return buf.Width * buf.Height * sizeof(single) *4
	public Vert as kri.buf.Texture:
		get: return buf.A[0].Tex
	public Quat as kri.buf.Texture:
		get: return buf.A[1].Tex
	
	public def constructor(w as uint, h as uint, bv as byte, bq as byte, filt as bool):
		allowFilter = filt
		buf.init(w,h)
		buf.mask = 0
		for i in range(2):
			bits = (bv,bq)[i]
			continue	if not bits
			buf.mask |= 1<<i
			buf.emitAuto(i,bits).bind()
			ft = (allowFilter and not i)
			buf.A[i].Tex.filt(ft,false)


#---------	RENDER VERTEX SPATIAL TO UV		--------#

public class Update( kri.rend.tech.Basic ):
	private final sa		= kri.shade.Smart()
	public final channel	as byte
	
	public def constructor(texId as byte, putId as bool):
		super('bake.mesh')
		channel = texId
		# surface shader
		sa.add( '/uv/bake_v', '/lib/quat_v', '/uv/bake_f' )
		if putId:
			sa.add( '/uv/set/geom_v', '/uv/bake_g' )
		else:	sa.add('/uv/set/norm_v')
		sa.fragout('re_vertex','re_quat')
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	public override def process(con as kri.rend.Context) as void:
		con.DepthTest = false
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			a = kri.Ant.Inst.attribs
			continue if not e.visible or not tag or\
				not attribs(true, e, a.vertex,a.quat,a.tex[channel])
			assert tag.uvChannel == 0
			tag.stamp = kri.Ant.Inst.Time
			n = (null,e.node)[tag.worldSpace]
			kri.Ant.Inst.params.modelView.activate(n)
			tag.buf.activate(3)
			if tag.clearTarget:
				con.ClearColor( Color4(0f,0f,0f,0f) )
				tag.clearTarget = false
			sa.use()
			e.mesh.draw(1)
