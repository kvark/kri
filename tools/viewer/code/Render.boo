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
	public	final	grForward	as support.light.group.Forward
	public	final	grDeferred	as support.defer.Group	= null

	public	BaseColor 	as Graphics.Color4:
		set:	rEmi.pBase.Value = value
	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = rEmi.backColor = value
	
	public def constructor(pc as kri.part.Context):
		grForward	= support.light.group.Forward( 8, false, pc )
		grDeferred	= support.defer.Group( 3, grForward.con, pc )
		rChain.renders.AddRange((rSkin,rClear,rZcull,rEmi,grForward,grDeferred))
	
	public def gen(sh as Scheme) as kri.rend.Basic:
		if sh == Scheme.Simple:
			for ren in (rClear,rZcull,grForward,grDeferred):
				ren.active = false
			rEmi.active = rEmi.fillDepth = true
		if sh == Scheme.Forward:
			rClear.active = grDeferred.active = rEmi.fillDepth = false
			for ren in (rZcull,rEmi,grForward):
				ren.active = true
		if sh == Scheme.Deferred:
			for ren in (rClear,grForward,rEmi):
				ren.active = false
			grDeferred.active = true
		return rChain
