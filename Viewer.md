# Introduction #

KRI Viewer is a GUI tool that allows you to view a scene without writing any code. This can be useful for starters, because now it's easy to get an idea about how the Blender scene will look like in different modes. It's supposed to inspire people to start writing the actual logic code to control the loading and rendering.

It's also very useful in production, because both artist and programmer can easily see the scene before loading a full-blown environment. They can catch possible errors earlier and greately reduce the time spent for communication. It also decreases the number iterations needed to get new assets working with an existing system.

Viewer is using GTK# as GUI toolkit, so it works on any major OS (X, Linux, Win). GTK# install is required and can be downloaded from Novell Mono [FTP](http://ftp.novell.com/pub/mono/gtk-sharp/).


# Details #

## Concept: Viewer but not Editor ##

Viewer specifically doesn't support any modifications to the scene. This limitation is there by design, because there are next to no scenarios in which editing a scene outside the main 3D modelling progeam (Blender) is useful. Any modification that you may want to do will in the end have to be done on artist side, so allowing the one to do it in a temporary "dirty" way will only harm the situation.


## Features ##

Upon loading a scene Viewer puts everything into a tree. For example, you can browse the following path: _entity->material->animation->curve_. Here is the list of node types: entity, node, material, camera, light, skeleton, animation record, animation curve, meta data, texture unit, mesh, vertex storage, vertex attribute, particle emitter, particle manager, particle behavior.

The following nodes are not expanded by default in order to prevent UI overloading. You will need to activate them (double-click or hit Enter) if you want to see the contents:
  * Animation curves
  * Material meta data and texture units
  * Particle manager behaviors
  * Vertex storage attributes

When a node is selected, some additional information and functionality is shown in the bottom right corner. For example, you can start an animation from there or see camera's FOV.

## Rendering pipelines ##

Viewer can switch rendering pipelines on the fly. Currently the following modes are supported:
  1. **Debug**	- for tracking vertex attributes values.
  1. **Simple**	- for minimal weight environment. Supports models with colors but no quaternions provided. Doesn't produce shadows and particles.
  1. **Forward**	- universal lighting and shadowing approach. Renders particles and produces shadows for spot lights.
  1. **Deferred**	- standard deferred technique of baking the material properties in the full-screen map. Supports particles but no shadows (yet).
  1. **Layered**	- layered deferred technique. Uses Blender-style texture units application.
  1. **HierZ**	- hierarchical Z-culling. Shows dynamic bounding boxes and effectively culls objects using hierarchical Z-buffer.
  1. **Anaglyph**	- fake anaglyph rendering. Red-Cyan image is reconstructed from given depth and color layers. Doesn't produce an acceptable quality of stereo imaging at the moment, so I advice to use _Stereo_ mode instead.


## Command line options ##

You can use the following options to initialize the Viewer:
  * _-pipe_="Pipeline"		- to set a rendering pipeline
  * _scene_="SceneFile"	- to load a scene file
  * _-draw_	- to enable image auto-update
  * _-stereo_	- to enable anaglyph stereo mode
  * _-play_	- to play all animations on start

All these functions are also accessible via Viewer GUI.


## Trouble-shooting ##

Generally you can see the message log in a Box after scene loaded or some frame rendered. If you by any chance encounter a crash - there will be a special dialog shown with an option to report the bug automatically. Additionally, an _exception.txt_ file in the Viewer folder is created with the exception stack printed. I would appreciate if you file an issue via google code upon facing a bug, providing as much information about the crash as you can (error message, scene, your actions, etc).