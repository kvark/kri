namespace support.bake.surf

import OpenTK.Graphics


public class Tag( kri.ITag ):
	public worldSpace	as bool = true		# in world space
	public clearTarget	as bool = true		# clear textures
	public uvChannel	as byte = 0			# tex-coord channel
	public stamp		as double	= -1f	# last update
	public final buf	= kri.buf.Holder( mask:0 )
	public final allowFilter	as bool		# allow results filtering
	
	public Size as uint:
		get: return buf.getInfo().Size * sizeof(single)*4
	public Vert as kri.buf.Texture:
		get: return buf.at.color[0] as kri.buf.Texture
	public Quat as kri.buf.Texture:
		get: return buf.at.color[1] as kri.buf.Texture
	
	public def constructor(w as uint, h as uint, bv as byte, bq as byte, filt as bool):
		allowFilter = filt
		for i in range(2):
			bits = (bv,bq)[i]
			continue	if not bits
			buf.mask |= 1<<i
			pf = kri.rend.Context.FmColor[bits>>3]
			buf.at.color[i] = t = kri.buf.Texture( intFormat:pf )
			t.filt( allowFilter and not i, false )
		buf.resize(w,h)


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
			tag.buf.bind()
			if tag.clearTarget:
				con.ClearColor( Color4(0f,0f,0f,0f) )
				tag.clearTarget = false
			sa.use()
			e.mesh.draw(1)
