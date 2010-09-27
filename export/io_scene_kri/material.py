__author__ = ['Dzmitry Malyshau']
__bpydoc__ = 'Material module of KRI exporter.'

import bpy
from io_scene_kri.common	import *


###  MATERIAL:UNIT   ###

def save_mat_unit(mtex):
	out = Writer.inst
	# map input chunk
	out.begin('unit')
	colored = ('diffuse','emission','spec','reflection')
	flat = ['normal','mirror','hardness']
	supported = flat + list('color_'+x for x in colored)
	current = list(x for x in supported	if mtex.__getattribute__('use_map_'+x))
	print("\t\t",'affect:', ','.join(current))
	out.text( *(current+['']) )
	tc,mp = mtex.texture_coords, mtex.mapping
	print("\t\t", tc,'input,', mp,'mapping')
	out.text(tc)
	if tc == 'UV':	# dirty: resolving the UV layer ID
		name = mtex.uv_layer
		if not len(name):
			print("\t\t(w)",'UV layer name is not set')
		primary = -1
		for ent in bpy.context.scene.objects:
			if ent.type != 'MESH': continue
			mlist = []	# need 'flat' function
			for ms in ent.material_slots:
				mlist.extend( ms.material.texture_slots )
			if not mtex in mlist: continue
			uves = [ut.name for ut in ent.data.uv_textures]
			if not name in uves:
				print("\t\t\t(w)",'entity has incorrect UV names')
				cur = 0
			else:	cur = uves.index( name )
			if cur == primary: continue
			primary = cur
		if primary == -1:
			print("\t\t(w)",'failed to resolve UV layer')
			primary = 0
		else:
			print("\t\t(i) layer: %s -> %d" % (mtex.uv_layer, primary))
		out.pack('B',primary)
	if tc == 'OBJECT':	out.text( mtex.object.name )
	if tc == 'ORCO':	out.text( mp )
	out.end()


###  MATERIAL:TEXTURE TYPES   ###

def save_mat_image(mtex):
	out = Writer.inst
	it = mtex.texture
	assert it
	# tex mapping
	out.begin('t_map')
	if mtex.mapping_x != 'X' or mtex.mapping_y != 'Y' or mtex.mapping_z != 'Z':
		print("\t(w)",'tex coord swizzling not supported')
	out.array('f', tuple(mtex.offset) + tuple(mtex.scale) )
	out.end()
	# colors
	out.begin('t_color')
	out.pack('3f', it.factor_red, it.factor_green, it.factor_blue )
	out.pack('3f', it.intensity, it.contrast, it.saturation )
	out.end()
	# ramp
	if it.use_color_ramp:
		ramp = it.color_ramp
		num = len(ramp.elements)
		print("\t\tramp: %d stages" % (num))
		out.begin('t_ramp')
		out.text( ramp.interpolation )
		out.pack('B',num)
		for el in ramp.elements:
			out.pack('f', el.position)
			out.array('f', el.color)
		out.end()

	if it.type == 'ENVIRONMENT_MAP':
		# environment map chunk
		env = mtex.texture.environment_map
		if env.source != 'IMAGE_FILE':
			clip = (env.clip_start, env.clip_end)
			print("\t\tenviron: %s [%.2f-%2.f]" % (env.mapping,clip[0],clip[1]))
			view = ''
			if not env.viewpoint_object:
				print("\t\t(w)",'View point is not set')
			else: view = env.viewpoint_object.name
			out.begin('t_env')
			out.pack('2BH3f', env.source=='ANIMATED',
				env.depth, env.resolution, env.zoom,
				clip[0], clip[1] )
			out.text( env.mapping, view )
			out.end()
			return
	elif it.type == 'BLEND':	# blend chunk
		out.begin('t_blend')
		out.text( it.progression )
		out.pack('B', it.flip_axis == 'VERTICAL')
		out.end()
		return
	elif it.type == 'NOISE':	# noise chunk
		out.begin('t_noise')
		out.end()
	elif it.type != 'IMAGE':
		print("\t\t(w)",'unknown texture type', it.type )
		return
	# image path
	img = it.image
	assert img
	out.begin('t_path')
	fullname = img.filepath
	print("\t\t", img.source, ':',fullname)
	name = '/'+fullname.rpartition('\\')[2].rpartition('/')[2]
	if name != fullname:
		print("\t\t(w) path cut to:", name)
	out.text( name)
	out.end()
	if it.type == 'IMAGE':
		# texture image sampling
		out.begin('t_samp')
		repeat = (it.extension == 'EXTEND')
		out.pack( '3B', repeat,
			it.use_mipmap, it.use_interpolation )
		out.end()
	if img.source == 'SEQUENCE':
		# image sequence chunk
		user = mtex.texture.image_user
		out.begin('t_seq')
		out.pack( '3H', user.frames, user.offset, user.start_frame )
		out.end()
	elif img.source != 'FILE':
		print("\t\t(w)",'bad image source')


###  MATERIAL:CORE   ###

def save_mat(mat):
	out = Writer.inst
	print("[%s] %s" % (mat.name,mat.type))
	out.begin('mat')
	out.text( mat.name )
	out.end()
	# diffuse subroutine
	def save_diff_intensity(val):
		save_color( mat.diffuse_color )
		out.pack('2f', mat.alpha, val )
	def save_diffuse(model):
		out.begin('m_diff')
		save_diff_intensity( mat.diffuse_intensity )
		out.text(model)
		out.end()
	if mat.strand:	# hair strand
		st = mat.strand
		out.begin('m_hair')
		out.pack('4fB', st.root_size, st.tip_size, st.shape,
			st.width_fade, st.use_tangent_shading )
		out.end()
	# particle halo material
	if	mat.type == 'HALO':
		out.begin('m_halo')
		halo = mat.halo
		if halo.use_ring or halo.use_lines or halo.use_star:
			print("\t(w)",'halo rights, lines & star modes are not supported')
		data = (halo.size, halo.hardness, halo.add)
		out.array('f', data)
		out.pack('B', halo.use_texture)
		print("\tsize: %.2f, hardness: %.0f, add: %.2f" % data)
		out.end()
		save_diffuse('')
	# regular surface material
	elif	mat.type == 'SURFACE':
		out.begin('m_surf')
		parallax = 0.5
		out.pack('B3f', mat.use_shadeless, parallax,
			mat.ambient, mat.translucency )
		out.end()
		out.begin('m_emis')
		save_diff_intensity( mat.emit )
		out.end()
		sh = (mat.diffuse_shader, mat.specular_shader)
		print("\tshading: %s %s" % sh)
		save_diffuse(sh[0])
		# specular
		out.begin('m_spec')
		save_color( mat.specular_color )
		out.pack('3f', mat.specular_alpha,\
			mat.specular_intensity, mat.specular_hardness)
		out.text( sh[1] )
		out.end()
		mirr = mat.raytrace_mirror
		if mirr.use:
			print("\tmirror: ", mirr.reflect_factor)
			out.begin('m_mirr')
			save_color( mat.mirror_color )
			out.pack('2f', 1.0, mirr.reflect_factor)
			out.end()
	else: print("\t(w)",'unsupported type')
	# texture units
	for mt in mat.texture_slots:
		if not mt: continue
		print("\t+map:", mt.name)
		save_mat_unit(mt)
		save_mat_image(mt)
