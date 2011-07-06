namespace support.cull.box

import OpenTK.Graphics.OpenGL

public class Draw( kri.rend.Basic ):
	public	final	bu		= kri.shade.Bundle()
	private	final	mesh	= kri.Mesh( BeginMode.Points )
	private	final	va		= kri.vb.Array()
	
	public def constructor(con as support.cull.Context):
		sa = bu.shader
		for name in ('quat','tool'):
			text = kri.shade.Code.Read("/lib/${name}_v")
			sa.add( kri.shade.Object( ShaderType.GeometryShader, name, text ))
		sa.add( '/cull/draw_v', '/cull/draw_g', '/white_f' )
		mesh.nVert = con.maxn
		mesh.vbo.Add( con.bound )
		mesh.vbo.Add( con.spatial )
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate(false)
		link.SetDepth(0f,false)
		mesh.render( va,bu, kri.TransFeedback.Dummy )
