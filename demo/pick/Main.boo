namespace demo.pick

import OpenTK


[System.STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',24):
		view = kri.ViewScreen()
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera( rangeIn:40f, rangeOut:60f )
		view.scene.lights.Add( kri.Light() )
	
		rem = kri.rend.Emission( fillDepth:true )
		rem.backColor = Graphics.Color4(0f,0.3f,0.5f,1)
		licon = support.light.Context(2,8)
		
		view.ren = rm = kri.rend.Manager(false)
		#rm.add('skin',	1,	kri.kit.skin.Update(true) )
		rm.add('emi',	3,	rem)
		rm.add('pick',	3,	support.pick.Render(win,2,8), 'emi')
		rm.add('fill',	2,	support.light.Fill(licon) )
		rm.add('app',	4,	support.light.Apply(licon), 'emi','fill')
		#rm.add('xxx',	2,	kri.rend.debug.Attrib(), 'app')
		
		win.core.anim = al = kri.ani.Scheduler()
		str as string = null
		if argv.Length:
			str = argv[0]
		Task( view.scene.entities, al, str )
		#e = at.scene.entities[0]
		#skel = e.seTag[of kri.kit.skin.Tag]().skel
		#skel.moment(3f, skel.find('Action'))
		#al.add( kri.kit.skin.Anim(e,'Action') )
		win.Run(30.0,30.0)
