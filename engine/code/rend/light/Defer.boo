namespace kri.rend.light.defer

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade


public class Context:
	public final buf		= kri.frame.Buffer()
	public final tool		= kri.shade.Object('/light/defer/sh_f')

	public def constructor():
		buf.mask = 0
		tar = kri.Texture( TextureTarget.Texture2DArray )
		for i in range(3):
			buf.A[i].layer(tar,i)
			buf.mask |= 1<<i


#---------	LIGHT PRE-PASS	--------#

public class Bake( kri.rend.Basic ):
	protected final sa		= Smart()
	protected final context	as kri.rend.light.Context
	protected final sphere	as kri.Mesh
	private final buf		as kri.frame.Buffer
	private final texDep	= par.Value[of kri.Texture]('depth')
	private final va		= kri.vb.Array()
	private final static 	geoQuality	= 1
	private final static	pif = PixelInternalFormat.Rgba16f

	public def constructor(dc as Context, lc as kri.rend.light.Context):
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
		sphere = kri.kit.gen.Sphere( geoQuality, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )

	public override def setup(far as kri.frame.Array) as bool:
		wid = far.Width
		het = far.Height
		buf.init(wid,het)
		buf.A[0].Tex.bind()
		kri.Texture.InitArray( pif, wid, het, 3 )
		return true
		
	public override def process(con as kri.rend.Context) as void:
		con.activate()
		texDep.Value = buf.A[-1].Tex = con.Depth
		buf.activate()
		con.SetDepth(0f,false)
		con.ClearColor( Graphics.Color4(0f,0f,0f,0f) )
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		using blender = kri.Blender():
			blender.add()
			for l in kri.Scene.current.lights:
				continue	if l.fov != 0f
				kri.Ant.Inst.params.activate(l)
				sa.use()
				sphere.draw(1)
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )


#---------	LIGHT APPLICATION	--------#

public class Apply( kri.rend.tech.Meta ):
	private final buf	as kri.frame.Buffer
	private final pTex	= kri.shade.par.Texture('light')
	# init
	public def constructor(dc as Context):
		super('lit.defer', false, null,
			'bump','emissive','diffuse','specular','glossiness')
		buf = dc.buf
		pTex.Value = buf.A[0].Tex
		dict.unit( pTex )
		shobs.Add( dc.tool )
		shade('/light/defer/apply')
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		drawScene()
