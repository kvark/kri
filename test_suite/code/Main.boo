namespace test

[System.STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen()
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		
		#rlis.Add( ShaderLink() )
		#rlis.Add( PolygonOffset() )
		#rlis.Add( TextureRead() )
		#rlis.Add( Feedback(null) )
		rlis.Add( DrawToStencil() )
		
		ant.views.Add( view )
		ant.Run(10.0,10.0)
