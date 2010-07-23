Hello, stranger!

Kvark's Reality Interface welcomes you!
In order to build me, you need to fulfill the following conditions:
  * have boo-0.9.4 or newer
  * have .Net-2.0-compatible framework installed
  * have opentk-1.0 sources checked out in the neighbour 'opentk' folder
  * have SharpDevelop 3.2+ or MonoDevelop-boo built from the trunk
  * have Catalyst 9.10,9.11 or 10.5+ driver installed

That's it. Open the test/code/kri.sln with your IDE and build everything.
If you did everything correctly, it will use the project dependancies to build OpenTK first, then 'ext', then 'engine' and all the demoes after.

In order to use 'export' you need to put/link export/export_scene_kri.py into the Blender's script/io folder (and restart it). You'll need the latest Blender version to export correctly. As of today, this version is 2.53-beta.

If something goes wrong, contact me through the project tracker:
http://code.google.com/p/kri/issues/list
or directly by email: kvarkus <dog> gmail com

Good luck with that!
kv