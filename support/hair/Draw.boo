namespace support.hair

import kri.buf

public class Fill( kri.rend.Basic ):
	public final sa			= kri.shade.Smart()
	private final buf		as Holder	= null
	private static doGeom	= true	#should be
	
	public def constructor(licon as support.light.Context, buffer as Holder):
		assert licon
		buf = buffer
		sa.add( '/lib/quat_v','/lib/tool_v' )
		sa.add( licon.getFillShader() )
		if doGeom:
			pref =  '/part/draw/fur/fill_'
			sa.add( pref+'v', pref+'g' )
		else:
			sa.add( 'text/fill_point_v' )
		sa.link( kri.Ant.Inst.slotParticles, licon.dict, kri.Ant.Inst.dict )
	
	public override def process(con as kri.rend.Context) as void:
		con.SetDepth(1f,true)
		sa.use()
		for pe in kri.Scene.Current.particles:
			pe.va.bind()
			continue	if not pe.prepare()
			for lit in kri.Scene.Current.lights:
				continue	if not lit.depth
				if buf.mask:
					buf.at.color[0] = lit.depth
				else:
					buf.at.depth = lit.depth
				buf.bind()
				kri.Ant.Inst.params.activate(lit)
				kri.shade.Smart.UpdatePar()
				pe.owner.draw(0)



public class Draw( kri.rend.part.Meta ):
	public final texLit		as kri.shade.par.Texture	= null
	private static doGeom	= true	#should be

	public def constructor(lc as support.light.Context):
		super('part.light.draw', doGeom, 'strand','diffuse','specular','glossiness')
		bAdd = 0f
		# drawing
		if lc:
			#bAdd = 1f
			texLit = lc.texLit
			dict.attach( lc.dict )
			shobs.Add( lc.getApplyShader() )
			shade(( '/lib/math_g','/lib/math_f' ))
			shade( '/part/draw/fur/lit/draw_'+suf	for suf in ('v','g','f') )
		elif doGeom:
			shade( '/part/draw/fur/draw_'+suf		for suf in ('v','g','f') )
		else:
			shade(( '/part/draw/fur/draw_point_v', '/part/draw/fur/draw_f' ))
	
	public override def process(con as kri.rend.Context) as void:
		con.activate( ColorTarget.Same, 0f, false )
		if texLit:
			for lit in kri.Scene.Current.lights:
				kri.Ant.Inst.params.activate(lit)
				texLit.Value = lit.depth
				drawScene()
		else:	drawScene()
	
	public override def onManager(man as kri.part.Manager) as void:
		pass
		#beh = man.seBeh[of support.hair.Behavior]()
		#pSegment.Value = beh.pSegment.Value



public class DrawChild( kri.rend.part.Meta ):
	public final texLit		as kri.shade.par.Texture	= null
	private static doGeom	= true	#should be

	public def constructor(pc as kri.part.Context, lc as support.light.Context):
		super('part.child.light.draw', doGeom, 'strand','diffuse','child')
		bAdd = 0f
		# drawing
		shobs.AddRange(( pc.sh_tool, pc.sh_child ))
		suffixes = ('child_v','g','f')
		if lc:
			#bAdd = 1f
			texLit = lc.texLit
			dict.attach( lc.dict )
			shobs.Add( lc.getApplyShader() )
			shade( '/part/draw/fur/lit/draw_'+suf	for suf in suffixes )
		elif doGeom:
			shade( '/part/draw/fur/draw_'+suf		for suf in suffixes )
		else:
			shade(( '/part/draw/fur/draw_point_v', '/part/draw/fur/draw_f' ))

	protected override def update(pe as kri.part.Emitter) as uint:
		mat = pe.mat
		assert mat
		me = mat.Meta['child'] as support.corp.child.Meta
		assert me
		return me.num

	public override def process(con as kri.rend.Context) as void:
		con.activate( ColorTarget.Same, 0f, false )
		if texLit:
			for lit in kri.Scene.Current.lights:
				kri.Ant.Inst.params.activate(lit)
				texLit.Value = lit.depth
				drawScene()
		else:	drawScene()
