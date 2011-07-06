namespace viewer

import OpenTK

public class RenderSet:
	public	final	rChain	as kri.rend.Chain	= null
	public	final	rClear	= kri.rend.Clear()
	public	final	rColor	= kri.rend.Color()
	public	final	rEmi	= kri.rend.Emission()
	public	final	rSkin	= support.skin.Universal()
	public	final	rAttrib	= kri.rend.debug.Attrib()
	public	final	rSurfBake	= support.bake.surf.Update(0,false)
	public	final	rNormal		as support.light.normal.Apply	= null
	public	final	rDummy		as kri.rend.part.Dummy			= null
	public	final	rParticle	as kri.rend.part.Standard		= null
	public	final	grForward	as support.light.group.Forward	= null
	public	final	grDeferred	as support.defer.Group			= null
	public	final	grCull		= support.cull.Group(256)
	public	final	rZcull		= kri.rend.Wrap( grCull.rZ )

	public	BaseColor 	as Graphics.Color4:
		set:	rEmi.pBase.Value = value
	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = rEmi.backColor = value
	
	public def constructor(profile as bool, samples as byte, pc as kri.part.Context):
		# create render groups
		rDummy		= kri.rend.part.Dummy(pc)
		rParticle	= kri.rend.part.Standard(pc)
		grForward	= support.light.group.Forward( 8, false )
		grDeferred	= support.defer.Group( 3, 10, grForward.con, null )
		rNormal		= support.light.normal.Apply( grForward.con )
		# create and populate render chain
		rChain = kri.rend.Chain(samples,0,0)
		rChain.renders.AddRange((rSkin,rClear,rZcull,grCull,rColor,rEmi,rSurfBake,rNormal,
			grForward,grDeferred,rDummy,rParticle,rAttrib))
		rChain.doProfile = profile
	
	public def gen(str as string) as kri.rend.Basic:
		for ren in rChain.renders:
			ren.active = false
		if str == 'Debug':
			rAttrib.active = true
		if str == 'Simple':
			for ren in (rSkin,rZcull,rColor,rDummy,rNormal,rSurfBake):
				ren.active = true
			rColor.fillColor = true
			rColor.fillDepth = false
		if str == 'Forward':
			for ren in (rSkin,rZcull,rEmi,rParticle,rSurfBake,grForward):
				ren.active = true
			rEmi.fillDepth = false
		if str in ('Deferred','Layered'):
			for ren in (rSkin,rZcull,grDeferred,rParticle,rSurfBake):
				ren.active = true
			grDeferred.Layered = (str == 'Layered')
		if str in ('HierZ'):
			for ren in (rSkin,grCull,rEmi):
				ren.active = true
			rEmi.fillDepth = false
		return rChain
