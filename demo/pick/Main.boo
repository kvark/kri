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
		texDebug = kri.shade.par.Texture('debug')
		
		rd = kri.rend.debug.Map(false,false,-1,texDebug)
		rSkin = support.skin.Update(true)
		rAt = kri.rend.debug.Attrib()
		rd.active = rSkin.active = rAt.active = false
		
		view.ren = rm = kri.rend.Manager()
		rm.put('skin',	1,	rSkin)
		rm.put('emi',	3,	rem,	'skin')
		rm.put('pick',	3,	support.pick.Render(win,2,8), 'emi')
		rm.put('fill',	2,	support.light.spot.Fill(licon),	'skin' )
		rm.put('app',	4,	support.light.spot.Apply(licon), 'emi','fill')
		rm.put('tex',	2,	rd,		'fill')
		rm.put('xxx',	2,	rAt, 	'app','skin')
		
		str as string = null
		if argv.Length:
			str = argv[0]
		task = Task( view.scene.entities, str )
		win.core.anim = task.animan
		texDebug.Value = task.texture
		#e = at.scene.entities[0]
		#skel = e.seTag[of kri.kit.skin.Tag]().skel
		#skel.moment(3f, skel.find('Action'))
		#al.add( kri.kit.skin.Anim(e,'Action') )
		win.Run(30.0,30.0)
