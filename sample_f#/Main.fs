module sample

let ant = new kri.Ant("kri.conf",0)

let view = kri.ViewScreen(8u,0u)
let rchain = kri.rend.Chain()
view.ren <- rchain
let rlis = rchain.renders

if true then
  view.scene <- kri.Scene("main")
  view.cam <- kri.Camera()

  let mesh = kri.kit.gen.Cube(OpenTK.Vector3.One)
  let con = kri.load.Context()
  let ent = kri.kit.gen.Entity(mesh,con)
  ent.node <- kri.Node("main")
  ent.node.local.pos.Z <- -30.0f
  ent.node.local.rot <- OpenTK.Quaternion.FromAxisAngle( OpenTK.Vector3.UnitX, -1.0f )
  view.scene.entities.Add(ent)

  rlis.Add( kri.rend.EarlyZ() )
  rlis.Add( kri.rend.debug.MapDepth() )
  //rlis.Add( rem = kri.rend.Emission() )
  //rem.pBase.Value = OpenTK.Graphics.Color4.Gray

  let licon = kri.rend.light.Context(2u,8u)
  //licon.setExpo(120f, 0.5f)
  //rlis.Add( kri.rend.light.Fill(licon) )
  //rlis.Add( kri.rend.light.Apply(licon) )
  rlis.Add( kri.rend.FilterCopy() )

ant.views.Add( view )
ant.Run(1.0,1.0)
