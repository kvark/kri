namespace support.stereo

import kri.shade
import OpenTK.Graphics.OpenGL


public class Split( kri.rend.Basic ):
	public	final	pDepth		= par.Texture('depth')
	public	final	pColor		= par.Texture('color')
	public	focus		= 0.5
	public	final	dict		= par.Dict()
	public	final	pHalfEye	= par.Value[of single]('half_eye')
	public	final	pFocus		= par.Value[of single]('focus_dist')
	public	final	bu			= Bundle()
	private	final	vao			= kri.vb.Array()
	
	public def constructor():
		dict.var(pHalfEye,pFocus)
		dict.unit(pDepth,pColor)
		pHalfEye.Value = 1f
		bu.dicts.Add(dict)
		bu.shader.add('/stereo/split_'+s	for s in ('v','g','f'))
		bu.shader.add('/lib/quat_v','/lib/tool_v')
		bu.link()
	
	public def getFocus(cam as kri.Camera) as single:
		return (1f-focus)*cam.rangeIn + focus*cam.rangeOut
	
	public override def process(link as kri.rend.link.Basic) as void:
		pDepth.Value = link.Depth
		pColor.Value = link.Input
		link.activate( link.Target.New, 0f, false )
		link.ClearColor()
		scene = kri.Scene.Current
		if not scene:	return
		pFocus.Value = getFocus( kri.Camera.Current )
		using blend = kri.Blender():
			blend.add()
			for ent in scene.entities:
				ent.render(vao,bu)
