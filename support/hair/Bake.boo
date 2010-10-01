namespace support.hair

import OpenTK
import OpenTK.Graphics.OpenGL

#-------------------------------------------#
#		Base attributes baking Render		#
#-------------------------------------------#

public class Bake( kri.rend.Basic ):
	public final vbo	= kri.vb.Attrib()
	public final s_face	= kri.shade.Smart()
	public final s_vert	= kri.shade.Smart()
	public final tf		= kri.TransFeedback(1)
	private final pWid	= kri.shade.par.Value[of int]('width')
	private final pVert	= kri.shade.par.Texture('vert')
	private final pQuat	= kri.shade.par.Texture('quat')
	private final pInit	= kri.shade.par.Value[of Vector4]('fur_init')

	public def constructor():
		super(false)
		# init dictionary
		d = kri.shade.rep.Dict()
		d.var(pWid)
		d.var(pInit)
		d.unit(pVert,pQuat)
		# init shader
		ant = kri.Ant.Inst
		com = ant.dataMan.load[of kri.shade.Object]('/part/fur/base/main_v')
		s_face.add('/lib/quat_v','/part/fur/base/face_v')
		s_vert.add('/lib/quat_v','/part/fur/base/vert_v')
		for sa in s_face,s_vert:
			sa.add(com)
			sa.feedback(false, 'to_prev','to_base')
			sa.link( ant.slotAttributes, d, ant.dict )
		# init fake vertex attrib for drawing
		vbo.Semant.Add( kri.vb.Info(
			size:1, slot:0, type:VertexAttribPointerType.UnsignedByte ))

	public override def process(con as kri.rend.Context) as void:
		for e in kri.Scene.Current.entities:
			tCur	= e.seTag[of Tag]()
			continue	if not tCur
			pInit.Value = tCur.param
			tf.Bind( tCur.Data )
			tCur.va.bind()
			tBake	= e.seTag[of support.bake.surf.Tag]()
			if tBake:	# emit from face
				continue	if tBake.stamp<0f
				vbo.initAll( tCur.pixels )
				pWid.Value	= tBake.buf.Width
				pVert.Value	= tBake.Vert
				pQuat.Value	= tBake.Quat
				s_face.use()
				using kri.Discarder(true), tf.catch():
					GL.DrawArrays( BeginMode.Points, 0, tCur.pixels )
			else:		# from vertices
				at = kri.Ant.Inst.attribs
				e.enable(true, (at.vertex, at.quat) )
				s_vert.use()
				assert tCur.pixels >= e.mesh.nVert
				#todo: what's left in the array?
				e.mesh.draw(tf)
			tCur.stamp = kri.Ant.Inst.Time
