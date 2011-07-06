namespace support.cull

public class Context:
	public	final	spatial	= kri.vb.Attrib()
	public	final	bound	= kri.vb.Attrib()
	public	final	maxn	as uint
	public	final	pTex	= kri.shade.par.Texture('input')
	public	final	dict	= kri.shade.par.Dict()
	private next	= 0
	
	public def constructor(n as uint):
		maxn = n
		kri.Help.enrich(bound,	4,'low','hai')
		bound.initUnit(n)
		kri.Help.enrich(spatial,4,'pos','rot')
		dict.unit(pTex)
	
	public def genTag() as box.Tag:
		if next>=maxn:
			kri.lib.Journal.Log('Box: objects limit reached')
			return null
		return box.Tag(next++)
	
	public def fillScene(scene as kri.Scene) as void:
		for e in scene.entities:
			e.tags.Add( genTag() )



public class Group( kri.rend.Group ):
	public	final	con			as Context					= null
	public	final	rBoxFill	as box.Fill					= null
	public	final	rBoxUp		as box.Update				= null
	public	final	rZ			as kri.rend.EarlyZ			= null
	public	final	rFill		as hier.Fill				= null
	public	final	rApply		as hier.Apply				= null
	public	final	rMap		as kri.rend.debug.MapDepth	= null

	public def constructor(maxn as uint):
		con = Context(maxn)
		rBoxFill = box.Fill(con)
		rBoxUp = box.Update(con)
		rZ = kri.rend.EarlyZ()
		rFill = hier.Fill(con)
		rApply = hier.Apply(con)
		rMap = kri.rend.debug.MapDepth()
		rMap.active = false
		super(rBoxFill,rZ,rFill,rApply,rBoxUp,rMap)

