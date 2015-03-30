# Meet #

The best way to see the engine in action is to try one of the demos. A typical _KRI_ demo depends on the following components:
  * .NET framework version: 3.5+
  * graphics card: G80+, 2400HD+
  * driver OpenGL version: 3.2+
  * [Blender-2.5](http://www.blender.org/download/get-blender/) for [Exporter](Exporter.md)
  * [GTK#](http://ftp.novell.com/pub/mono/gtk-sharp/) - for [Viewer](Viewer.md)

The driver support is very limited as both ATI/NV like to introduce bugs and implement the spec in some weird way. At least Catalyst 10.8+ supposed to work correctly at the moment.


# Involve #

## Building the project ##

My windows development environment consists of SharpDevelop + Red Gate's Reflector. Boo that is bundled with IDE is sufficient.
  1. download SharpDevelop 3.2+
  1. download OpenTK, set as a reference for each KRI-related project you build
  1. download [GLWidget](http://sourceforge.net/projects/glwidget/) if you need [Viewer](Viewer.md)


## Viewing the exported scene ##

In order to use exporter from Blender 2.57+, you need to copy or link "kri/export/io\_scene\_kri" into the Blender's "scripts/addons/" folder. Then you can launch Blender and enable the plugin ("User Preferrences -> Add-ons"). Exporting is done via "File->Export->KRI" menu command. It will allow you to chose a path to destination file and configure several parameters (see [Exporter](Exporter.md) for details).

[Viewer](Viewer.md) allows you to load the scene with no hassle. In order to build it you'll need to make sure all GTK# dependencies are resolved correctly.


## Exposing the modularity ##

The engine is designed to be solid and not require any modifications on feature addition. As much as possible is done in the user space:
  * [RenderPipeline](RenderPipeline.md) with user renders
  * animations interaction
  * material [MetaData](MetaData.md) (and meta-techniques that render it)
  * [Entity](Entity.md) tags (and tag processing renders)
  * loader slots

The _support_ library contains some useful extension modules, which also serve as good references:
  * **Bake**: baking vertex data into UV texture (tag + render)
  * **Fur**: dynamic inertial shell-based fur (tag + meta + renders)
  * **HDR**: high dynamic range lighting & blooming (render)
  * **Pick**: object mouse picking processing (tag + render)
  * **Skin**: skeletal animations (tag + anim + render)


## Drawing ##

All drawing is performed by Renders (see [RenderPipeline](RenderPipeline.md). If you want to draw something (an existing Entity or a texture, whatever), you need to create a render. If you draw outside the render code, the result is undefined.
The render drawing to a given context is not aware about the screen or auxiliary FBO being its target. The output is defined by the underlying meta-render or specified directly via _Context.Screen_ property.

There is a rich class hierarchy of renders that you should use. The most handy ones are:
  * _Basic_: the hierarchy root
  * _Filter_: parse an existing texture
  * _Technique_: draw objects in batches with manual shading
  * _MetaTechnique_: draw objects with authomatic meta-component linkage


## Animating ##

The application logic & event handling should be performed in Animations.
```
# Animation Interface
public interface IBase:
	def onFrame(time as double) as uint
```
That's simple: just inherit from it and do whatever you want inside the _onFrame_ routine. Don't forget to attach it to _Ant_ or to any meta-animation.
There are several system animations worth mentioning:
  * _Skin_: character skeletons
  * _Particle_: particle systems
  * _ControlMouse_: simple user mouse rotation



# Develop #

## Help! ##

If you encountered a problem and don't see a reason, check the following components:
  1. skipped loader chunks: `kri.load.Native.skipped`
  1. required renders are used (omni light render has no effect on spot lights)
  1. light & camera range values: `kri.Projector.range*`
  1. rejected techniques: `kri.Material.tech[tech_name] == kri.shade.Smart.Fixed`
  1. rejected entities: `kri.Entity.va[tech_name] == kri.vb.Array.Default`
  1. rejected particle techniques: `kri.part.Entity.techReady[tech_name] == false`


## Create custom Renders ##

There are several GL states that are guaranteed to have their default values.
You should switch back these values in default on render finish if using them:
  * `EnableCap.Blend`: off
  * `EnableCap.RasterizerDiscard`: off
  * `EnableCap.StensilTest`: off
  * `GL.DepthFunc`: lequal
  * `GL.PolygonMode`: fill
  * `GL.CullFace`: back


## Use tangental space ##

Tangental space is represented by the pair: Quaternion + Handness bit.
Quaternion (tangent->local) is passed as _at\_quat_ vertex attribute, while handness is stored within W component of the vertex position (_at\_vertex.W_).

Follow these steps in the shader to transform an arbitrary vector _v_ into the tangent space:
  1. get world->tangent space rotation:
> > ` vec4 quat = qinv(qmul( s_model.rot, at_quat )); `
> > where: `s_model` = modelview -> world spatial transform
  1. tranfrom vertex: `v_t = qrot(quat, v);`
  1. fix handness: `v_t.x *= at_vertex.w;`