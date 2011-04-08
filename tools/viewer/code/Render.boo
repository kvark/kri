namespace viewer

import OpenTK


public enum Scheme:
	Simple

public class RenderSet:
	public	final	rList	= kri.rend.Chain()
	public	final	rZcull	= kri.rend.EarlyZ()
	public	final	rEmi	= kri.rend.Emission()
	
	public def constructor():
		rEmi.pBase.Value = Graphics.Color4.Blue
		rList.renders.AddRange((rZcull,rEmi))
	
	public def gen(sh as Scheme) as kri.rend.Basic:
		return rList
