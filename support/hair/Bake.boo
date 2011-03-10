namespace support.hair

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

#-----------------------------------------------#
#		Hair base attributes baking Render		#
#-----------------------------------------------#


public class Bake( kri.rend.Basic ):
	public final vbo	= kri.vb.Attrib()
	public final tf		= kri.TransFeedback(1)
	# face section
	public final s_face	= Smart()
	private final pWid	= par.Value[of int]('width')
	private final pVert	= par.Texture('vert')
	private final pQuat	= par.Texture('quat')
	private final pInit	= par.Value[of Vector4]('fur_init')
	# vertex section
	public final s_vert	= Smart()
	private final pStretch	= par.Value[of single]('vertex_ratio')
	private final tbuf = (
		kri.buf.Texture(),
		kri.buf.Texture())

	public def constructor(pc as kri.part.Context):
		super(false)
		# init dictionary
		d = rep.Dict()
		d.var(pWid)
		d.var(pInit)
		d.var(pStretch)
		d.unit(pVert,pQuat)
		# init shader
		com = Object.Load('/part/fur/base/main_v')
		s_face.add('/lib/quat_v','/part/fur/base/face_v')
		s_vert.add('/lib/quat_v','/part/fur/base/vert_v')
		for sa in s_face,s_vert:
			sa.add( com, pc.sh_tool )
			sa.feedback(false, 'to_prev','to_base')
			sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
		# init fake vertex attrib for drawing
		vbo.Semant.Add( kri.vb.Info(
			size:1, slot:0, type:VertexAttribPointerType.UnsignedByte ))

	public override def process(con as kri.rend.link.Basic) as void:
		for e in kri.Scene.Current.entities:
			tCur	= e.seTag[of Tag]()
			continue	if not tCur
			assert tCur.pixels
			pInit.Value = tCur.param
			kri.Ant.Inst.params.modelView.activate( e.node )
			tf.Bind( tCur.Data )
			tCur.va.bind()
			if tCur.stamp<0f:
				vbo.initAll( tCur.pixels )
			tBake	= e.seTag[of support.bake.surf.Tag]()
			if tBake:	# emit from face
				continue	if tBake.stamp<0f
				pWid.Value	= tBake.buf.getInfo().wid
				pVert.Value	= tBake.Vert
				pQuat.Value	= tBake.Quat
				s_face.use()
			else:		# from vertices
				pStretch.Value = e.mesh.nVert * 1f / tCur.pixels
				ats = kri.Ant.Inst.attribs
				(pVert.Value = tbuf[0]).init( SizedInternalFormat.Rgba32f,	e.findAny(ats.vertex) )
				(pQuat.Value = tbuf[1]).init( SizedInternalFormat.Rgba32f,	e.findAny(ats.quat) )
				s_vert.use()
			using kri.Discarder(true), tf.catch():
				GL.DrawArrays( BeginMode.Points, 0, tCur.pixels )
			tCur.stamp = kri.Ant.Inst.Time
