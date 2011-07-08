Hello, stranger!

Kvark's Reality Interface welcomes you!
In order to build me, you need to fulfill the following conditions:
  * have boo-0.9.4 or newer
  * have .Net-3.5-compatible framework installed
  * have opentk-1.0 sources checked out in the neighbour 'opentk' folder
  * have SharpDevelop 3.2+ or MonoDevelop-boo built from the trunk
  * have Catalyst 9.10,9.11 or 10.5+ driver installed

That's it. Open the tools/viewer/code/viewer.sln with your IDE and build everything.
If you did everything correctly, it will use the project dependencies to build OpenTK first, then 'ext', 'engine' and 'support' and then, finally, 'viewer'. You can also download OpenTK binaries and setup the dependencies by hand.

In order to use the exporter you need to put or link export/io_scene_kri into the Blender's scripts/addons folder (and restart it). You'll also need to enable this addon in Blender properties. As of today, the Blender version supported is 2.58.

If something goes wrong, contact me through the project tracker:
http://code.google.com/p/kri/issues/list
or directly by email: kvarkus <dog> gmail com

Good luck with that!
kv