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
	public	final	rEmi	= kri.rend.Emission()
	public	final	rSkin	= support.skin.Update(true)
	public	final	rSurfBake	= support.bake.surf.Update(0,false)
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
		rChain.renders.AddRange((rSkin,rClear,rZcull,rEmi,rSurfBake,grForward,grDeferred,rDummy,rParticle))
		if texFun:
			proxy = kri.shade.par.UnitProxy(texFun)
			rChain.renders.Add( kri.rend.debug.Map(false,false,-1,proxy))
	
	public def gen(sh as Scheme) as kri.rend.Basic:
		if sh == Scheme.Simple:
			for ren in (rClear,rZcull,rParticle,grForward,grDeferred):
				ren.active = false
			rEmi.active = rDummy.active = rEmi.fillDepth = true
		if sh == Scheme.Forward:
			rClear.active = grDeferred.active = rDummy.active = rEmi.fillDepth = false
			for ren in (rZcull,rEmi,rParticle,grForward):
				ren.active = true
		if sh == Scheme.Deferred:
			for ren in (rClear,grForward,rEmi,rDummy):
				ren.active = false
			grDeferred.active = rParticle.active = true
		return rChain
