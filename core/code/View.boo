namespace kri

public class ViewBase:
	public virtual def resize(wid as int, het as int) as bool:
		return true
	public virtual def update() as void:
		pass


# Renders a scene with camera to some buffer
public class View(ViewBase):
	# rendering
	public virtual Link as kri.rend.link.Basic:
		get: return null
	public ren		as rend.Basic	# root render
	# view
	public cam		as Camera	= null
	public scene	as Scene	= null

	public override def resize(wid as int, het as int) as bool:
		return ren!=null and ren.setup( kri.buf.Plane(wid:wid,het:het) )
	
	public override def update() as void:
		Scene.current = scene
		if cam and Link:
			cam.aspect = Link.Frame.getInfo().Aspect
			Ant.Inst.params.activate(cam)
		if ren and ren.active:
			ren.process(Link)
		elif Link:
			Link.activate(false)
			Link.ClearColor()
		vb.Array.Default.bind()
		Scene.current = null
	
	public def updateSize() as bool:
		return ren!=null and Link!=null and ren.setup( Link.Frame.getInfo() )
	
	public def countVisible() as int:
		if not scene: return 0
		return List[of Entity](e
			for e in scene.entities	if e.Visible[cam]
			).Count


# View for rendering to screen
public class ViewScreen(View):
	public final area	= OpenTK.Box2(0f,0f,1f,1f)
	public final link	= kri.rend.link.Screen()
	public override Link as kri.rend.link.Basic:
		get: return link
	public override def resize(wid as int, het as int) as bool:
		return resize(0,0,wid,het)
	public def resize(ofx as int, ofy as int, wid as int, het as int) as bool:
		sc = link.screen
		pl = sc.plane
		pl.wid	= cast(int, wid*area.Width	)
		pl.het	= cast(int, het*area.Height	)
		sc.ofx	= cast(int, wid*area.Left	) + ofx
		sc.ofy	= cast(int, het*area.Top	) + ofy
		return super.resize(wid,het)
