namespace viewer

import OpenTK

public enum Scheme:
	Simple
	Forward

public class RenderSet:
	public	final	rChain	= kri.rend.Chain()
	public	final	rClear	= kri.rend.Clear()
	public	final	rZcull	= kri.rend.EarlyZ()
	public	final	rEmi	= kri.rend.Emission()
	public	final	rSkin	= support.skin.Update(true)
	public	final	grForward	= support.light.group.Forward()
	
	public	BaseColor 	as Graphics.Color4:
		set:	rEmi.pBase.Value = value
	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = rEmi.backColor = value
	
	public def constructor():
		rChain.renders.AddRange((rSkin,rClear,rZcull,rEmi,grForward))
	
	public def gen(sh as Scheme) as kri.rend.Basic:
		if sh == Scheme.Simple:
			rClear.active = rZcull.active = grForward.active = false
			rEmi.active = rEmi.fillDepth = true
		if sh == Scheme.Forward:
			rClear.active = rEmi.fillDepth = false
			rZcull.active = rEmi.active = grForward.active = true
		return rChain
