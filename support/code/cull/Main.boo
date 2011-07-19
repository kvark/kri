namespace support.cull

public class Context:
	public	final	spatial	= kri.vb.Attrib()
	public	final	bound	= kri.vb.Attrib()
	public	final	maxn	as uint
	public	final	pTex	= kri.shade.par.Texture('input')
	public	final	dict	= kri.shade.par.Dict()
	public	final	frame	as kri.gen.Frame	= null
	private next	as uint	= 0
	
	public def constructor(n as uint):
		maxn = n
		kri.Help.enrich(bound,	4,'low','hai')
		bound.initUnit(n)
		kri.Help.enrich(spatial,4,'pos','rot')
		dict.unit(pTex)
		m = kri.Mesh( nVert:maxn )
		m.buffers.AddRange(( bound, spatial ))
		frame = kri.gen.Frame('box',m)
	
	public def reset() as void:
		next = 0
	
	public def genId() as uint:
		if next>=maxn:
			kri.lib.Journal.Log('Box: objects limit reached')
			next = 0
		return next++
	
	public def fillScene(scene as kri.Scene) as void:
		for e in scene.entities:
			if not e.seTag[of box.Tag]():
				e.tags.Add( box.Tag() )




public class Group( kri.rend.Group ):
	public	final	con			as Context					= null
	# renders
	public	final	rBoxFill	as box.Fill					= null
	public	final	rBoxDraw	as box.Draw					= null
	public	final	rBoxUp		as box.Update				= null
	public	final	rFill		as hier.Fill				= null
	public	final	rApply		as hier.Apply				= null
	public	final	rMap		as kri.rend.debug.MapDepth	= null
	# signatures
	public	final	sBoxFill	= 'box.fill'
	public	final	sBoxDraw	= 'box.draw'
	public	final	sBoxUp		= 'box.up'
	public	final	sFill		= 'z.fill'
	public	final	sApply		= 'z.app'
	public	final	sMap		= 'z.map'

	public def constructor(maxn as uint):
		con = Context(maxn)
		rBoxFill = box.Fill(con)
		rBoxDraw = box.Draw(con)
		rBoxUp = box.Update(con)
		rFill = hier.Fill(con)
		rApply = hier.Apply(con)
		rMap = kri.rend.debug.MapDepth()
		rMap.active = false
		super(rBoxFill,rFill,rApply,rBoxUp,rMap)
	
	public def fill(rm as kri.rend.Manager, skin as string, sZ as string, sEmi as string) as void:
		rm.put(sBoxFill,	2,rBoxFill,	skin)
		rm.put(sBoxDraw,	1,rBoxDraw,	sBoxFill,sEmi)
		rm.put(sBoxUp,		1,rBoxUp,	sBoxFill)
		rm.put(sFill,		1,rFill,	sZ)
		rm.put(sApply,		1,rApply,	sFill,sBoxFill)
		rm.put(sMap,		1,rMap,		sFill,sEmi)
