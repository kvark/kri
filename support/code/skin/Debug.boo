namespace support.skin

public class Debug( kri.rend.Basic ):
	public	final	vbo		= kri.vb.Attrib()
	public	final	frame	as kri.gen.Frame
	public	final	bu		= kri.shade.Bundle()
	
	public def constructor():
		# create mesh
		kri.Help.enrich(vbo,4,'pos','rot','par')
		m = kri.Mesh()
		m.buffers.Add(vbo)
		frame = kri.gen.Frame('skeleton',m)
		# create shader
		bu.shader.add('/skin/debug_v','/skin/debug_g','/color_f','/lib/quat_v','/lib/tool_v')
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate(false)
		visited = List[of kri.Skeleton]()
		scene = kri.Scene.Current
		if not scene:	return
		for ent in scene.entities:
			tag = ent.seTag[of Tag]()
			if tag==null or tag.skel==null or tag.skel in visited:
				continue
			visited.Add( tag.skel )
			bones = tag.skel.bones
			frame.mesh.nVert = bones.Length
			# fill data array
			data = array[of OpenTK.Vector4]( bones.Length*3 )
			nw = tag.skel.node.World
			sp as kri.Spatial
			for i in range(bones.Length):
				bw = bones[i].World
				sp.combine(bw,nw)
				data[3*i+0] = kri.Spatial.GetPos(sp)
				data[3*i+1] = kri.Spatial.GetRot(sp)
				data[3*i+2] = OpenTK.Vector4.Zero
			# upload to mesh
			vbo.init(data,true)
			frame.draw(bu)
