namespace support.light.defer

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade
import kri.buf


public class Context:
	public final buf		= Holder()
	public final tool		= kri.shade.Object.Load('/light/defer/sh_f')

	public def constructor():
		#buf.emitArray(3)
		for i in range(3):
			buf.at.color[i] = Texture()


#---------	LIGHT PRE-PASS	--------#

public class Bake( kri.rend.Basic ):
	protected final sa		= Smart()
	protected final context	as support.light.Context
	protected final sphere	as kri.Mesh
	private final buf		as Holder
	private final texDep	= par.Value[of kri.buf.Texture]('depth')
	private final va		= kri.vb.Array()
	private final static 	geoQuality	= 1
	private final static	pif = PixelInternalFormat.Rgba16f

	public def constructor(dc as Context, lc as support.light.Context):
		super(false)
		buf = dc.buf
		context = lc
		# baking shader
		sa.add( '/light/defer/bake_v', '/light/defer/bake_f', '/lib/defer_f' )
		sa.add( dc.tool )
		sa.add( *kri.Ant.Inst.libShaders )
		sa.fragout('ca','cb','cc')
		d = rep.Dict()
		d.unit(texDep)
		sa.link( kri.Ant.Inst.slotAttributes, d, lc.dict, kri.Ant.Inst.dict )
		# create geometry
		va.bind()	# the buffer objects are bound in creation
		sphere = kri.gen.Sphere( geoQuality, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )

	public override def setup(pl as kri.buf.Plane) as bool:
		buf.at.color[0].samples = 3
		buf.resize( pl.wid, pl.het )
		return true
		
	public override def process(con as kri.rend.Context) as void:
		con.activate()
		buf.at.depth = texDep.Value = con.Depth
		buf.bind()
		con.SetDepth(0f,false)
		con.ClearColor( Graphics.Color4(0f,0f,0f,0f) )
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		using blender = kri.Blender():
			blender.add()
			for l in kri.Scene.Current.lights:
				continue	if l.fov != 0f
				kri.Ant.Inst.params.activate(l)
				sa.use()
				sphere.draw(1)
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )


#---------	LIGHT APPLICATION	--------#

public class Apply( kri.rend.tech.Meta ):
	private final buf	as Holder
	private final pTex	= par.Texture('light')
	# init
	public def constructor(dc as Context):
		super('lit.defer', false, null,
			'bump','emissive','diffuse','specular','glossiness')
		buf = dc.buf
		pTex.Value = buf.at.color[0] as Texture
		dict.unit( pTex )
		shobs.Add( dc.tool )
		shade('/light/defer/apply')
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		drawScene()
