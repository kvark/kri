namespace viewer

import OpenTK

public enum Scheme:
	Simple
	Forward
	Deferred


public class RenderSet:
	public	final	rChain	= kri.rend.Chain()
	public	final	rClear	= kri.rend.Clear()
	public	final	rZcull	= kri.rend.EarlyZ()
	public	final	rColor	= kri.rend.Color()
	public	final	rEmi	= kri.rend.Emission()
	public	final	rSkin	= support.skin.Update(true)
	public	final	rSurfBake	= support.bake.surf.Update(0,false)
	public	final	rNormal		as support.light.normal.Apply
	public	final	rDummy		as kri.rend.part.Dummy
	public	final	rParticle	as kri.rend.part.Standard
	public	final	grForward	as support.light.group.Forward
	public	final	grDeferred	as support.defer.Group	= null

	public	BaseColor 	as Graphics.Color4:
		set:	rEmi.pBase.Value = value
	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = rEmi.backColor = value
	
	public def constructor(pc as kri.part.Context, texFun as callable() as kri.buf.Texture):
		rDummy		= kri.rend.part.Dummy(pc)
		rParticle	= kri.rend.part.Standard(pc)
		grForward	= support.light.group.Forward( 8, false )
		grDeferred	= support.defer.Group( 3, grForward.con, null )
		rNormal		= support.light.normal.Apply( grForward.con )
		rChain.renders.AddRange((rSkin,rClear,rZcull,rColor,rEmi,rSurfBake,rNormal,
			grForward,grDeferred,rDummy,rParticle))
		if texFun:
			proxy = kri.shade.par.UnitProxy(texFun)
			rChain.renders.Add( kri.rend.debug.Map(false,false,-1,proxy))
	
	public def gen(sh as Scheme) as kri.rend.Basic:
		for ren in rChain.renders:
			ren.active = false
		if sh == Scheme.Simple:
			for ren in (rSkin,rZcull,rColor,rDummy,rNormal,rSurfBake):
				ren.active = true
			rColor.fillColor = true
			rColor.fillDepth = false
		if sh == Scheme.Forward:
			for ren in (rSkin,rZcull,rEmi,rParticle,rSurfBake,grForward):
				ren.active = true
			rEmi.fillDepth = false
		if sh == Scheme.Deferred:
			for ren in (rSkin,rZcull,grDeferred,rParticle,rNormal,rSurfBake):
				ren.active = true
		return rChain
