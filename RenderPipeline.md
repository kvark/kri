# Introduction #

There are two major concepts of a renderable object exist:
  * Object draws itself, encapsulating the drawing mechanics. This allows such specific objects like water or glowing sphere to be introduced with easy. However, this approach lacks in flexibility comparing to the next one.
  * _Renders_ draw objects. This provides a powerful basis for various shadow techniques, an early z-cull optimization and an easy switch to wireframe when needed for debug purposes. Custom shading of water surfaces and other special objects is achieved by special _Techniques_ that affect only selected objects.

Generally _Renders_ can be divided in 2 groups: filters and techniques. Filters take one input texture and produce some output from it by drawing a full-screen quad with applied shader.


# Rendering Technique #

Technique is designed to draw a subset of objects in some specific way. It doesn't require input and usually produces some output. Each material is supposed to have a shader that represents a technique and implements it. When rendering, the technique tries to activate the corresponding shader of a drawing object. If there is no shader associated, the special _construction_ functionality occurs.

Construction method is specific for each technique. It's supposed to produce a shader, that keeps dependencies inside (see [ShaderParam](ShaderParam.md)), and to associate it with a given material. Generally it consists of the following steps:
  1. create a shader program
  1. attach objects & libraries
  1. link (this is where uniforms are resolved)

After the shader activation, the technique tries to activate the corresponding VAO of an object. This VAO must have all required VBO activated and custom vertex attributes data specified (see [Entity](Entity.md)). If there is no VAO associated, a new one is created with a given list of vertex attributes, which are used by the technique.

# Pipeline #

Renders can be organized in a graph or a list. The major problem is the connection between them. There are following components accessed by a Render:
  * Input texture
  * Output framebuffer (not necessary the screen)
  * Custom parameter textures
  * Depth as either a texture or a target FBO attachment

Render doesn't need to know whether it draws to the screen or not. It also doesn't need to know about the existence of intermediate buffers, created by the render manager for input & output. Besides that, the manager shouldn't create more of these buffers than required, what also applies to the depth attachment. The final design of a Render includes following points:
  * Render specifies **bNeedInput** constant flag in the constructor. Manager puts the result of the previous operation in the input slot if the flag is set on the current render. By this flag manager also defines the last render in a chain that draws to the intermediate buffer, while all following Renders draw to the screen (or any abstract output buffer for this manager).
  * Render is given a special **Context** object that contains a set of textures, including depth & input (only if needed). This context may contain any other specific textures that are used by other renders and are treated like custom params. It's up to render to decide the usage of parameters: first can attach them to FBO and draw into, while the next can just bind them and use by the shader.
  * Context has the _activate_ method that accepts a boolean parameter **bUseDepth**, which activates the output framebuffer. This activation may cause the creation of an intermediate buffer by the context. If the flag is set, the existing depth texture is attached to the output FBO and the depth test is enabled. Otherwise, the depth texture is supplied in the context. In both cases the texture is created if not already exists.


# Implementation #
```
#---------	BASIC RENDER	--------#
public class Basic:
	public			active	as bool = true
	public final	bInput	as bool
	public def constructor(inp as bool):
		bInput = inp
	public virtual def setup(far as kri.frame.Array) as bool:
		return true
	public virtual def process(con as Context) as void:
		pass

public class Filter(Basic):
	protected final sa		= kri.shade.Smart()
	protected final texIn	= kri.shade.par.Texture(0, 'input')
	protected final dict	= kri.shade.rep.Dict()
	public def constructor():
		super(true)
		dict.unit(texIn)
	public override def process(con as Context) as void:
		texIn.Value = con.Input
		con.activate()
		sa.use()
		kri.Ant.inst.emitQuad()
```

The abstract technique code is a little more complex. It manages material & entity activation of a drawing object:
```
#---------	GENERAL TECHNIQUE	--------#

	public static comparer	as IComparer[of Batch]	= null
	protected	final	extraDict	= kri.vb.Dict()
	protected	final	butch		= List[of Batch]()
	
	public struct Updater:
		public final fun	as callable() as int
		public def constructor(f as callable() as int):
			fun = f

	protected def constructor(name as string):
		super(name)
	public abstract def construct(mat as kri.Material) as kri.shade.Bundle:
		pass
	protected virtual def getUpdater(mat as kri.Material) as Updater:
		return Updater() do() as int:
			return 1

	protected def addObject(e as kri.Entity) as void:
		if not e.visible:
			return
		tempList = List[of Batch]()
		atar	as (kri.shade.Attrib)	= null
		vao as kri.vb.Array = null
		if not e.va.TryGetValue(name,vao):
			e.va[name] = vao = kri.vb.Array()
			atar = array[of kri.shade.Attrib]( kri.Ant.Inst.caps.vertexAttribs )
		if vao == kri.vb.Array.Default:
			return
		b = Batch(e,vao)
		for de in extraDict:
			b.dict.Add( de.Key, de.Value )
		for tag in e.enuTags[of kri.TagMat]():
			m = tag.mat
			b.num = tag.num
			b.off = tag.off
			prog as kri.shade.Bundle = null
			if not m.tech.TryGetValue(name,prog):
				m.tech[name] = prog = construct(m)
				if prog.shader and not prog.shader.Ready:
					# force attribute order
					prog.shader.attribAll( e.mesh.gatherAttribs() )
					prog.link()
			if prog == kri.shade.Bundle.Empty:
				continue
			if atar:	# merge attribs
				ats = prog.shader.attribs
				for i in range(atar.Length):
					if atar[i].name == ats[i].name:
						continue
					assert not atar[i].name
					atar[i] = ats[i]
			b.bu = prog
			b.up = getUpdater(m).fun
			tempList.Add(b)
		if atar:
			if not b.va.pushAll( e.mesh.ind, atar, e.CombinedAttribs ):
				e.va[name] = kri.vb.Array.Default
				return
		butch.AddRange(tempList)

	protected def drawScene() as void:
		butch.Clear()
		for e in kri.Scene.Current.entities:
			addObject(e)
		if comparer:
			butch.Sort(comparer)
		for b in butch:
			b.draw()
```

# Conclusion #

Proposed _Technique_ class provides an ability for rendering objects in any way you want. The major difference with the old approach is the treating objects & materials like _data holders_. This makes all magic possible like adding post-processing effects on the fly, having many shadow techniques used at once, performing early z-culling on demand, etc. All objects become open to your imagination of drawing them.

Once the material system is established, you can have renders loaded from external modules, what allows you to improve graphics of the application even after the release date.

The render pipeline can be organized using specified rule. This approach makes any render combination to work without each of them knowing what's happening around.


# Advanced ordering #

The new render scheduler was recently implemented. It balances the load of GPU, increasing the gaps between each render and its closest dependency. Larger gaps allow the graphics conveyer to work without stalls increasing the overall performance.

In order to use the scheduler the user should provide the following data for each render:
  * unique name
  * integer complexity
  * list of dependency render names

The main task of the scheduler is to produce an order of renders that is the most performance effective (stall-less). The key property is the _Distance_ = summarized complexity between the render and its closest dependency. The primary ordering task is to maximize the minimum distance. The secondary task is to maximize the sum of all distances.

The user may demand to reverse an order. In some circumstances this can increase the performance, dividing some gaps by the frame boundary.