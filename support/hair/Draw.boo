namespace support.hair

private class Fill( kri.rend.Basic ):
	public final sa			= kri.shade.Smart()
	public final buf		as kri.frame.Buffer
	public final targets	as (kri.part.Emitter)
	public def constructor(ren as kri.rend.light.Fill, dict as kri.shade.rep.Dict, tList as (kri.part.Emitter)):
		sa.add( '/lib/quat_v','/lib/tool_v' )
		sa.add( ren.sh_bake )
		if 'GS':
			sa.add( 'text/fill_v','text/fill_g' )
		else:
			sa.add( 'text/fill_point_v' )
		sa.link( kri.Ant.Inst.slotParticles, dict, kri.Ant.Inst.dict )
		buf = ren.buf
		targets = tList
	
	public override def process(con as kri.rend.Context) as void:
		sa.use()
		for pe in targets:
			pe.va.bind()
			continue	if not pe.prepare()
			for lit in kri.Scene.Current.lights:
				continue	if not lit.depth
				buf.A[ buf.mask-1 ].Tex = lit.depth
				kri.Ant.Inst.params.activate(lit)
				buf.activate()
				kri.shade.Smart.UpdatePar()
				pe.owner.draw()


public class Draw( kri.rend.part.Meta ):
	public final texLit		as kri.shade.par.Texture	= null
	private static doGeom	= true	#should be

	public def constructor(lc as kri.rend.light.Context):
		super('part.light.draw', doGeom, 'strand','diffuse')
		bAdd = 0f
		# drawing
		if lc:
			#bAdd = 1f
			texLit = lc.texLit
			dict.attach( lc.dict )
			shobs.Add( lc.getShadowProg() )
			shade( '/part/draw/fur/lit/draw_'+suf	for suf in ('v','g','f') )
		elif doGeom:
			shade( '/part/draw/fur/draw_'+suf		for suf in ('v','g','f') )
		else:
			shade(( '/part/draw/fur/draw_point_v', '/part/draw/fur/draw_f' ))
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(true,0f,false)
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
