module sample

let ant = new kri.Ant("kri.conf",0)

let view = kri.ViewScreen(8u,0u)
let rchain = kri.rend.Chain()
view.ren <- rchain
let rlis = rchain.renders

ant.views.Add( view )
ant.Run(1.0,1.0)
