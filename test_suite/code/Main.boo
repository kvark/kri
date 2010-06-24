namespace test

[System.STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen(8,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		
		#rlis.Add( Link() )
		#rlis.Add( Offset() )
		#rlis.Add( Read() )
		#rlis.Add( Feedback(null) )
		
		if 'TestZ':
			view.scene = kri.Scene('main')
			view.cam = kri.Camera()
			
			mesh = kri.kit.gen.Cube( OpenTK.Vector3.One )
			con = kri.load.Context()
			ent = kri.kit.gen.Entity( mesh, con )
			ent.node = kri.Node('main')
			ent.node.local.pos.Z = -30f
			ent.node.local.rot = OpenTK.Quaternion.FromAxisAngle( OpenTK.Vector3.UnitX, -1f )
			view.scene.entities.Add(ent)
			
			rlis.Add( kri.rend.EarlyZ() )
			rlis.Add( kri.rend.debug.MapDepth() )
			#rlis.Add( rem = kri.rend.Emission() )
			#rem.pBase.Value = OpenTK.Graphics.Color4.Gray
			
			licon = kri.rend.light.Context(2,8)
			#licon.setExpo(120f, 0.5f)
			#rlis.Add( kri.rend.light.Fill(licon) )
			#rlis.Add( kri.rend.light.Apply(licon) )
			rlis.Add( kri.rend.FilterCopy() )
		
		ant.views.Add( view )
		ant.Run(1.0,1.0)
