# To support reload properly, try to access a package var, if it's there, reload everything
if "bpy" in locals():
	import sys
	reload(sys.modules.get("io_scene_kri.export_kri", sys))


import bpy
from bpy.props	import *
from io_utils	import ImportHelper, ExportHelper
from io_scene_kri.export_kri	import save_scene
from io_scene_kri.common	import Settings


class ExportKRI(bpy.types.Operator, ExportHelper):
	'''Export to KRI scene format'''
	bl_idname = 'export_scene.kri_scene'
	bl_label = '-= KRI =- (.scene)'
	filename_ext = '.scene'
	st = Settings()

	filepath	= StringProperty( name='File Path',
		description='Filepath used for exporting the KRI scene',
		maxlen=1024, default='')
	quat_int	= BoolProperty( name='Process quaternions',
		description='Prepare mesh quaternions for interpolation',
		default=st.doQuatInt )
	put_uv		= BoolProperty( name='Put UV layers',
		description='Export vertex UVs',	default=st.putUv )
	put_color	= BoolProperty( name='Put color layers',
		description='Export vertex colors',	default=st.putColor )

	def execute(self, context):
		st = Settings()
		st.doQuatInt	= self.properties.quat_int
		st.putUv	= self.properties.put_uv
		st.putColor	= self.properties.put_color
		save_scene(self.properties.filepath, context, st)
		return {'FINISHED'}


# Add to a menu
def menu_func_export(self, context):
	self.layout.operator( ExportKRI.bl_idname, text=ExportKRI.bl_label )

def register():
	bpy.types.INFO_MT_file_export.append(menu_func_export)

def unregister():
	bpy.types.INFO_MT_file_export.remove(menu_func_export)

if __name__ == "__main__":
	register()
