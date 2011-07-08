namespace test

[System.STAThread]
def Main(argv as (string)):
	using kri.Window('kri.conf',0):
		view = kri.View()
		view.ren = rchain = kri.rend.Chain()
		rlis = rchain.renders
		kri.lib.Journal.Inst = log = kri.lib.Journal()
		
		#rlis.Add( ShaderLink() )
		#rlis.Add( PolygonOffset() )
		#rlis.Add( TextureRead() )
		#rlis.Add( Feedback() )
		#rlis.Add( DrawToStencil() )
		#rlis.Add( MultiResolve() )
		rlis.Add( Geometry() )
		
		view.resize(10,10)
		view.update()
		
		print string.Join("\n", log.messages.ToArray())