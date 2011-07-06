namespace kri.rend

import OpenTK.Graphics

#---------	COLOR CLEAR	--------#

public class Clear( Basic ):
	public backColor	= Color4.Black
	public override def process(link as link.Basic) as void:
		link.activate(false)
		link.ClearColor( backColor )


#---------	WRAPPER	--------#

public class Wrap( Basic ):
	public final	sub	as Basic	= null
	public def constructor(rend as Basic):
		sub = rend
	public override def process(link as link.Basic) as void:
		if sub: sub.process(link)


#---------	EARLY Z FILL	--------#

public class EarlyZ( tech.Sorted ):
	public final bu	= kri.shade.Bundle()
	public def constructor():
		super('zcull')
		# make shader
		bu.shader.add( '/zcull_v', '/empty_f', '/lib/tool_v', '/lib/quat_v', '/lib/fixed_v' )
		bu.link()
	public override def construct(mat as kri.Material) as kri.shade.Bundle:
		return bu
	public override def process(link as link.Basic) as void:
		link.activate( link.Target.None, 1f, true )
		link.ClearDepth(1f)
		drawScene()


#---------	INITIAL FILL EMISSION	--------#

public class Emission( tech.Meta ):
	public final pBase	= kri.shade.par.Value[of Color4]('base_color')
	public fillDepth	= false
	public backColor	= Color4.Black
	
	public def constructor():
		super('mat.emission', false, null, 'emissive','diffuse')
		shade('/mat_base')
		dict.var(pBase)
		pBase.Value = Color4.Black
	public override def process(link as link.Basic) as void:
		if fillDepth:
			link.activate( link.Target.Same, 1f, true )
			link.ClearDepth(1f)
		else: link.activate( link.Target.Same, 0f, false )
		link.ClearColor( backColor )
		drawScene()


#---------	ADD COLOR	--------#

public class Color( tech.Sorted ):
	private final bu	= kri.shade.Bundle()
	public fillColor	= false
	public fillDepth	= false
	public def constructor():
		super('color')
		bu.shader.add( '/color_v','/color_f', '/lib/quat_v','/lib/tool_v','/lib/fixed_v' )
		bu.link()
	public override def construct(mat as kri.Material) as kri.shade.Bundle:
		return bu
	public override def process(link as link.Basic) as void:
		if fillDepth:
			link.ClearDepth(1.0)
			link.activate( link.Target.Same, 1f, true )
		else:
			link.activate( link.Target.Same, 0f, false )
		if fillColor:
			link.ClearColor()
			drawScene()
		else:
			using blend = kri.Blender():
				blend.add()
				drawScene()


#---------	RENDER SSAO	--------#


#---------	RENDER EVERYTHING AT ONCE	--------#

public class All( tech.Sorted ):
	public def constructor():
		super('all')
	public override def construct(mat as kri.Material) as kri.shade.Bundle:
		bu = kri.shade.Bundle()
		bu.link()
		return bu
	public override def process(link as link.Basic) as void:
		link.activate( link.Target.Same, 0f, true )
		link.ClearDepth(1f)
		link.ClearColor()
		drawScene()
