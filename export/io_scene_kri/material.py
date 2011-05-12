__author__ = ['Dzmitry Malyshau']
__bpydoc__ = 'Material module of KRI exporter.'

import bpy
from io_scene_kri.common	import *


###  MATERIAL:UNIT   ###

def find_uv_layer(name):
	# dirty: resolving the UV layer ID
	for ent in bpy.context.scene.objects:
		if ent.type != 'MESH': continue
		mlist = []	# need 'flat' function
		for ms in ent.material_slots:
			mlist.extend( ms.material.texture_slots )
		if not mtex in mlist: continue
		uves = [ut.name for ut in ent.data.uv_textures]
		if name in uves:
			return uves.index( name )
		out.log(2,'w','entity (%s) has incorrect UV names' % (ent.name))
	return -1


def save_mat_unit(mtex):
	out = Writer.inst
	# map input chunk
	out.begin('unit')
	colored = ('diffuse','emission','spec','reflection')
	flat = ['normal','mirror','hardness','diffuse','specular','emit']
	supported = flat + list('color_'+x for x in colored)
	current = list(x for x in supported	if mtex.__getattribute__('use_map_'+x))
	out.logu(2, 'affects: ' + ','.join(current))
	out.text( *(current+['']) )
	tc,mp = mtex.texture_coords, mtex.mapping
	out.logu(2, '%s input, %s mapping' % (tc,mp))
	out.text(tc,mp)
	if tc == 'UV':
		lid,name = 0,mtex.uv_layer
		if len(name):
			lid = find_uv_layer(name)
			if lid == -1:
				out.log(2,'w','failed to resolve UV layer')
				lid = 0
			else:	out.logu(2, 'layer: %s -> %d' % (name,lid))
		else:	out.log(2,'w','UV layer name is not set')
		out.pack('B',lid)
	if tc == 'OBJECT':	out.text( mtex.object.name )
	out.end()
	out.begin('u_apply')
	out.text( mtex.blend_type, mtex.bump_objectspace )
	out.pack('3B', mtex.use_rgb_to_intensity, mtex.invert, mtex.use_stencil )
	save_color( mtex.color )
	out.pack('f', mtex.default_value )
	out.end()



###  MATERIAL:TEXTURE TYPES   ###

def save_mat_image(mtex):
	out = Writer.inst
	it = mtex.texture
	assert it
	out.logu(2, 'type: ' + it.type)
	# tex mapping
	out.begin('t_map')
	if mtex.mapping_x != 'X' or mtex.mapping_y != 'Y' or mtex.mapping_z != 'Z':
		out.log(2,'w','tex coord swizzling not supported')
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
		out.logu(2, 'ramp: %d stages' % (num))
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
			out.logu(2, 'environ: %s [%.2f-%2.f]' % (env.mapping,clip[0],clip[1]))
			view = ''
			if not env.viewpoint_object:
				out.log(2,'w','view point is not set')
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
		out.pack('B', it.use_flip_axis=='VERTICAL' )
		out.end()
		return
	elif it.type == 'NOISE':	# noise chunk
		out.begin('t_noise')
		out.end()
	elif it.type == 'NONE':
		out.begin('t_zero')
		out.end()
		return
	elif it.type != 'IMAGE':
		out.log(2,'w', 'unknown type')
		return
	# image path
	img = it.image
	assert img
	out.begin('t_path')
	fullname = img.filepath
	out.logu(2, '%s: %s' % (img.source,fullname))
	if Settings.cutPaths:
		name = '/'+fullname.rpartition('\\')[2].rpartition('/')[2]
	if fullname.find(name) not in (0,1):
		out.log(2,'w', 'path cut to: %s' % (name))
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
		out.log(2,'w','unknown image source')


###  MATERIAL:CORE   ###

def save_mat(mat):
	out = Writer.inst
	print("[%s] %s" % (mat.name,mat.type))
	out.begin('mat')
	out.text( mat.name )
	out.end()
	# diffuse subroutine
	def save_diffuse(model):
		out.begin('m_diff')
		save_color( mat.diffuse_color )
		out.pack('3f', mat.alpha, mat.diffuse_intensity, mat.emit)
		out.text(model)
		out.end()
	def save_specular(model):
		out.begin('m_spec')
		save_color( mat.specular_color )
		out.pack('3f', mat.specular_alpha, mat.specular_intensity, mat.specular_hardness)
		out.text(model)
		out.end()
	if mat.strand:	# hair strand
		st = mat.strand
		out.begin('m_hair')
		dist = -1.0
		if st.use_surface_diffuse:
			dist = st.blend_distance
		out.pack('4fBf', st.root_size, st.tip_size, st.shape,
			st.width_fade, st.use_tangent_shading, dist )
		out.text( st.uv_layer )
		out.end()
	# particle halo material
	if	mat.type == 'HALO':
		out.begin('m_halo')
		halo = mat.halo
		if halo.use_ring or halo.use_lines or halo.use_star:
			out.log(1,'w', 'halo rings, lines & star modes are not supported')
		data = (halo.size, halo.hardness, halo.add)
		out.array('f', data)
		out.pack('B', halo.use_texture)
		out.log(1,'i', 'size: %.2f, hardness: %.0f, add: %.2f' % data)
		out.end()
		save_diffuse('')
	# regular surface material
	elif	mat.type == 'SURFACE':
		out.begin('m_surf')
		parallax = 0.5
		out.pack('B3f', mat.use_shadeless, parallax,
			mat.ambient, mat.translucency )
		out.end()
		sh = (mat.diffuse_shader, mat.specular_shader)
		out.log(1,'i', 'shading: %s %s' % sh)
		save_diffuse(sh[0])
		save_specular(sh[1])
		mirr = mat.raytrace_mirror
		if mirr.use:
			out.log(1,'i', 'mirror: ' + mirr.reflect_factor)
			out.begin('m_mirr')
			save_color( mat.mirror_color )
			out.pack('2f', 1.0, mirr.reflect_factor)
			out.end()
	else:	out.log(1,'w','unsupported type')
	# texture units
	for mt in mat.texture_slots:
		if not mt: continue
		out.logu(1,'+map: ' + mt.name)
		save_mat_unit(mt)
		save_mat_image(mt)
