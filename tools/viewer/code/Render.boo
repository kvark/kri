namespace viewer

import OpenTK

public class RenderSet:
	public	final	rChain	= kri.rend.Chain()
	public	final	rClear	= kri.rend.Clear()
	public	final	rZcull	= kri.rend.EarlyZ()
	public	final	rColor	= kri.rend.Color()
	public	final	rEmi	= kri.rend.Emission()
	public	final	rSkin	= support.skin.Update(true)
	public	final	rSurfBake	= support.bake.surf.Update(0,false)
	public	final	rAttrib	= kri.rend.debug.Attrib()
	public	final	rNormal		as support.light.normal.Apply
	public	final	rDummy		as kri.rend.part.Dummy
	public	final	rParticle	as kri.rend.part.Standard
	public	final	grForward	as support.light.group.Forward
	public	final	grDeferred	as support.defer.Group	= null
	public	final	rBox	= kri.rend.box.Update()

	public	BaseColor 	as Graphics.Color4:
		set:	rEmi.pBase.Value = value
	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = rEmi.backColor = value
	
	public def constructor(profile as bool, pc as kri.part.Context, texFun as callable() as kri.buf.Texture):
		rDummy		= kri.rend.part.Dummy(pc)
		rParticle	= kri.rend.part.Standard(pc)
		grForward	= support.light.group.Forward( 8, false )
		grDeferred	= support.defer.Group( 3, grForward.con, null )
		rNormal		= support.light.normal.Apply( grForward.con )
		rChain.renders.AddRange((rSkin,rClear,rZcull,rColor,rEmi,rSurfBake,rNormal,
			grForward,grDeferred,rDummy,rParticle,rAttrib,rBox))
		rChain.doProfile = profile
		if texFun:
			proxy = kri.shade.par.UnitProxy(texFun)
			rChain.renders.Add( kri.rend.debug.Map(false,false,-1,proxy))
	
	public def gen(str as string) as kri.rend.Basic:
		for ren in rChain.renders:
			ren.active = false
		rBox.active = true
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
		return rChain
