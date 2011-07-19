namespace viewer

import OpenTK

public class RenderSet:
	# todo: use render manager
	public	final	rChain	as kri.rend.Chain	= null
	public	final	rMan	= kri.rend.Manager()
	public	final	rClear	= kri.rend.Clear()
	public	final	rZ		= kri.rend.EarlyZ()
	public	final	rColor	= kri.rend.Color()
	public	final	rSkin	= support.skin.Universal()
	public	final	rAttrib	= kri.rend.debug.Attrib()
	public	final	rSurfBake	= support.bake.surf.Update(0,false)
	public	final	rNormal		as support.light.normal.Apply	= null
	public	final	rDummy		as kri.rend.part.Dummy			= null
	public	final	rParticle	as kri.rend.part.Standard		= null
	public	final	grForward	as support.light.group.Forward	= null
	public	final	grDeferred	as support.defer.Group			= null
	public	final	grCull		= support.cull.Group(256)

	public	ClearColor	as Graphics.Color4:
		set:	rClear.backColor = grForward.rEmi.backColor = value
	
	public def constructor(profile as bool, samples as byte, pc as kri.part.Context):
		# create render groups
		rDummy		= kri.rend.part.Dummy(pc)
		rParticle	= kri.rend.part.Standard(pc)
		grForward	= support.light.group.Forward( 8, false )
		grDeferred	= support.defer.Group( 3, 10, grForward.con, null )
		rNormal		= support.light.normal.Apply( grForward.con )
		# create and populate render chain
		rChain = kri.rend.Chain(samples,0,0)
		rChain.renders.AddRange((rSkin,rClear,grCull,rColor,rSurfBake,rNormal,
			grForward,grDeferred,rDummy,rParticle,rAttrib))
		rChain.doProfile = profile
		# populate render manager
		sk = 'skin'
		sz = 'zcull'
		rMan.put('clear',	1,rClear)
		rMan.put(sk,		2,rSkin)
		rMan.put(sz,		2,rZ,		sk)
		rMan.put('color',	3,rColor,	'clear',sk)
		rMan.put('atr',		3,rAttrib,	sk)
		rMan.put('surf',	3,rSurfBake,sk)
		grForward.fill( rMan, sk, sz)
		grDeferred.fill( rMan, sz )
		grCull.fill( rMan, sk, sz, grForward.sEmi )
	
	public def gen(str as string) as kri.rend.Basic:
		grForward.BaseColor = Graphics.Color4.Black
		for ren in rChain.renders:
			ren.active = false
		if str == 'Debug':
			rAttrib.active = true
		if str == 'Simple':
			for ren in (rSkin,rZ,rColor,rDummy,rNormal,rSurfBake):
				ren.active = true
			rColor.fillColor = true
			rColor.fillDepth = false
		if str == 'Forward':
			for ren in (rSkin,rZ,rParticle,rSurfBake,grForward):
				ren.active = true
			grForward.rEmi.fillDepth = false
		if str in ('Deferred','Layered'):
			for ren in (rSkin,rZ,grDeferred,rParticle,rSurfBake):
				ren.active = true
			grDeferred.Layered = (str == 'Layered')
		if str in ('HierZ'):
			emi = grForward.rEmi
			for ren in (rSkin,rZ,grCull,emi, grCull.rBoxDraw):
				ren.active = true
			emi.fillDepth = false
			grForward.BaseColor = Graphics.Color4.DarkSlateGray
		return rMan
