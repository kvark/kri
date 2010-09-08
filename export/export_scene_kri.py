# coding: utf-8
__author__ = ['Dzmitry Malyshau']
__url__ = ('kvgate.com')
__version__ = '0.5'
__bpydoc__ = '''KRI scene exporter.
This script exports the whole scene to the KRI binary file.
'''

''' Math notes:
 The multiplication order is Matrix * vector
 Matrix[3] is the translation component
 Only right-handed matrix should be converted to quaternion
'''

import bpy
file_ext = '.scene'
out = None
kFrameSec = 1.0 / 25.0


class Settings:
	doQuatInt	= True
	putUv		= True
	putColor	= False
	logInfo		= True

class Writer:
	__slots__= 'fx','pos'
	def __init__(self,path):
		self.fx = open(path,'wb')
		self.pos = 0
	def pack(self,tip,*args):
		import struct
		assert self.pos
		self.fx.write( struct.pack('<'+tip,*args) )
	def array(self,tip,ar):
		import array
		assert self.pos
		array.array(tip,ar).tofile(self.fx)
	def text(self,*args):
		for s in args:
			n = len(s)
			assert n<256
			self.pack("B%ds"%(n), n,s)
	def begin(self,name):
		import struct
		assert len(name)<8 and not self.pos
		self.fx.write( struct.pack('<8sL',name,0) )
		self.pos = self.fx.tell()
	def end(self):
		import struct
		assert self.pos
		off = self.fx.tell() - self.pos
		self.fx.seek(-off-4,1)
		self.fx.write( struct.pack('<L',off) )
		self.fx.seek(+off+0,1)
		self.pos = 0

def save_color(rgb):
	for c in rgb:
		out.pack('B', int(255*c) )

def save_matrix(mx):
	import math
	pos = mx.translation_part()
	sca = mx.scale_part()
	rot = mx.to_quat()
	scale = (sca.x + sca.y + sca.z)/3.0
	if math.fabs(sca.x-sca.y) + math.fabs(sca.x-sca.z) > 0.01:
		print("\t(w)",'non-uniform scale:',str(sca))
	out.pack('8f',
		pos.x, pos.y, pos.z, scale,
		rot.x, rot.y, rot.z, rot.w )


###  ANIMATION CURVES   ###

def gather_anim(ob):
	ad = ob.animation_data
	if not ad: return []
	all = [ns.action for nt in ad.nla_tracks for ns in nt.strips]
	if ad.action and not ad.action in all:
		print("\t(w)",'current action is not finalized')
		all.append( ad.action )
	return all


def save_actions(ob,sym,symInd):
	import re
	if not ob: return
	for act in gather_anim(ob):
		offset,nf = act.get_frame_range()
		rnas,curves = {},set() # {elem_id}{attrib_name}[sub_id]
		indexator,n_empty = None,0
		# gather all
		for f in act.fcurves:
			bid,attrib = 0, f.data_path
			if not len(attrib):
				n_empty += 1
				continue
			# extract array name, index & target field
			mat = re.search('([\.\w]+)\[(.+)\]\.(\w+)',attrib)
			if mat:
				if not symInd: continue
				mg = mat.groups()
				curArray = ob
				for elem in mg[0].split('.'):
					curArray = curArray.__getattribute__(elem)
				if not indexator:
					indexator = curArray
				elif indexator != curArray:
					print("\t\t(w)", 'unknown array:', mg[0])
					continue
				sub = mg[1].strip('"')
				if sub == mg[1]: bid = 1 + int(sub)
				else: bid = 1 + indexator.keys().index(sub)
				attrib = mg[2]
			elif not sym: continue
			#print("\t\tpassed [%d].%s.%d" %(bid,attrib,f.array_index) )
			if not bid in rnas:
				rnas[bid] = {}
			if not attrib in rnas[bid]:
				rnas[bid][attrib] = []
			lis = rnas[bid][attrib]
			assert f.array_index == len(lis)
			lis.append(f)
		# write header or exit
		if not len(rnas): continue
		out.begin( 'action' )
		out.text( act.name )
		out.pack('f', nf * kFrameSec )
		out.end()
		print("\t+anim: '%s', %d frames, %d groups" % ( act.name,nf,len(act.groups) ))
		if n_empty:
			print("\t\t(w) %d empty curves detected" % (n_empty))
		# write in packs
		prefix = (sym,symInd)[indexator != None]
		for elem,it in rnas.items():
			for attrib,sub in it.items():
				curves.add( "%s[%d]" % (attrib,len(sub)) )
				out.begin('curve')
				assert elem<256 and len(attrib)<24
				out.text( prefix+ '.'+attrib )
				out.pack('2B', len(sub), elem )
				save_curve_pack( sub, offset )
				out.end()
		print("\t\t", ', '.join(curves) )

		

###  ACTION:CURVES   ###

def save_curve_pack(curves,offset):
	if not len(curves):
		print("\t\t(w)",'invalid curve pack')
		out.pack('H',0)
		return
	num = len( curves[0].keyframe_points )
	extra = curves[0].extrapolation
	#print "\t(i) %s, keys %d" %(curves,num)
	for c in curves:
		assert len(c.keyframe_points) == num
		assert c.extrapolation == extra
	out.pack('HB', num, (extra == 'LINEAR'))
	for i in range(num):
		def h0(k): return k.co
		def h1(k): return k.handle1
		def h2(k): return k.handle2
		kp = tuple(c.keyframe_points[i] for c in curves)
		x = kp[0].co[0]
		out.pack('f', (x-offset)*kFrameSec)
		#print ('Time', x, i, data)
		for fun in (h0,h1,h2):	# ignoring handlers time
			out.array('f', (fun(k)[1] for k in kp) )



###  MATERIAL:UNIT   ###

def save_mat_unit(mtex):
	# map input chunk
	out.begin('unit')
	colored = ('diff','emission','spec','reflection')
	supported = ['normal'] + list('color'+x for x in colored)
	current = list(x for x in supported	if mtex.__getattribute__('map_'+x))
	print("\t\t",'affect:', ','.join(current))
	out.text( *(current+['']) )
	tc,mp = mtex.texture_coordinates, mtex.mapping
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
	it = mtex.texture
	assert it
	# tex mapping
	out.begin('t_map')
	if mtex.x_mapping != 'X' or mtex.y_mapping != 'Y' or mtex.z_mapping != 'Z':
		print("\t(w)",'tex coord swizzling not supported')
	out.array('f', tuple(mtex.offset) + tuple(mtex.size) )
	out.end()
	# colors
	out.begin('t_color')
	out.pack('3f', it.factor_red, it.factor_green, it.factor_blue )
	out.pack('3f', it.brightness, it.contrast, it.saturation )
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
			it.mipmap, it.interpolation )
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
			st.width_fade, st.tangent_shading )
		out.end()
	# particle halo material
	if	mat.type == 'HALO':
		out.begin('m_halo')
		halo = mat.halo
		if halo.ring or halo.lines or halo.star:
			print("\t(w)",'halo rights, lines & star modes are not supported')
		data = (halo.size, halo.hardness, halo.add)
		out.array('f', data)
		out.pack('B', halo.texture)
		print("\tsize: %.2f, hardness: %.0f, add: %.2f" % data)
		out.end()
		save_diffuse('')
	# regular surface material
	elif	mat.type == 'SURFACE':
		out.begin('m_surf')
		parallax = 0.5
		out.pack('B3f', mat.shadeless, parallax,
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
	else: print("\t(w)",'unsupported type')
	# texture units
	for mt in mat.texture_slots:
		if not mt: continue
		print("\t+map:", mt.name)
		save_mat_unit(mt)
		save_mat_image(mt)


###  MESH   ###

def save_mesh(mesh,armature,groups,st):
	import mathutils
	def calc_TBN(verts, uvs):
		va = verts[1].co - verts[0].co
		vb = verts[2].co - verts[0].co
		n0 = n1 = va.cross(vb)
		tan,bit,hand = va,vb,1
		if len(uvs) and n1.dot(n1) > 0.0:
			ta = uvs[0][1] - uvs[0][0]
			tb = uvs[0][2] - uvs[0][0]
			tan = va*tb.y - vb*ta.y
			if tan.dot(tan)>0.0:
				bit = vb*ta.x - va*tb.x
				n0 = tan.cross(bit)
				hand = (-1.0 if n0.dot(n1) < 0.0 else 1.0)
			else:	tan,hand = va,0.0
		return (tan, bit, n0, hand, n1)

	class Vertex:
		__slots__= 'face', 'vert','vert2', 'coord', 'tex', 'color', 'normal', 'quat', 'dual'
		def __init__(self, v):
			self.face = None
			self.vert = v
			self.vert2 = None
			self.coord = v.co
			self.tex = None
			self.color = None
			self.normal = v.normal
			self.quat = None
			self.dual = -1

	class Face:
		__slots__ = 'v', 'vi', 'no', 'uv', 'color', 'mat', 'ta', 'hand', 'normal', 'wes'
		def __init__(self, face, m, ind = None, uves = None, colors = None):
			if not ind: # clone KRI face
				self.vi		= list(face.vi)
				self.hand	= face.hand
				self.mat	= face.mat
				return
			# this section requires optimization!
			# hint: try 'Recalculate Outside' if getting lighting problems
			self.mat = face.material_index
			self.vi = [ face.verts[i]	for i in ind   ]
			self.v  = tuple( m.verts[x]	for x in self.vi )
			self.no = tuple( x.normal	for x in self.v  )
			self.normal = ( face.normal, mathutils.Vector((0,0,0)) )[face.smooth]
			self.uv		= tuple(tuple( layer[i]	for i in ind ) for layer in uves)
			self.color	= tuple(tuple( layer[i]	for i in ind ) for layer in colors)
			t,b,n,hand,nv = calc_TBN(self.v, self.uv)
			self.wes = tuple( 3 * [0.1+nv.dot(nv)] )
			assert t.dot(t) > 0.0
			self.ta = t.normalize()
			self.hand = hand
	
	# 1: convert Mesh to Triangle Mesh
	for layer in mesh.uv_textures:
		if not len(layer.data):
			print("\t(e)",'UV layer is locked by the user')
			return
	ar_face = []
	for i,face in enumerate(mesh.faces):
		uves,colors,nvert = [],[],len(face.verts)
		for layer in ( mesh.uv_textures		if st.putUv	else [] ):
			d = layer.data[i]
			cur = tuple(mathutils.Vector(x) for x in (d.uv1,d.uv2,d.uv3,d.uv4))
			uves.append(cur)
		for layer in ( mesh.vertex_colors	if st.putColor	else [] ):
			d = layer.data[i]
			cur = tuple(mathutils.Vector(x) for x in (d.color1,d.color2,d.color3,d.color4))
			colors.append(cur)
		if nvert>=3:	ar_face.append( Face(face, mesh, (0,1,2), uves,colors) )
		if nvert>=4:	ar_face.append( Face(face, mesh, (0,2,3), uves,colors) )
	n_bad_uv = len(list( f for f in ar_face if f.hand==0.0 ))
	if n_bad_uv:
		print("\t(w) %d pure vertices detected" % (n_bad_uv))
	else: print("\tconverted to tri-mesh")
	if not len(ar_face):
		print("\t(e)",'objects without faces are not supported')
		return

	# 2: fill sparsed vertex array
	avg,set_vert = 0.0,{}
	for face in ar_face:
		avg += face.hand
		nor = face.normal
		for i in range(3):
			v = Vertex( face.v[i] ) 
			v.normal = (nor if nor.dot(nor)>0.1 else face.no[i])
			v.tex	= [layer[i] for layer in face.uv]
			v.color	= [layer[i] for layer in face.color]
			v.face = face
			vs = str((v.coord,v.tex,v.color,v.normal,face.hand))
			if not vs in set_vert:
				set_vert[vs] = []
			set_vert[vs].append(v)
	print("\t(i) %.2f avg handness" % (avg / len(ar_face)))
	
	# 3: update triangle indexes
	avg,ar_vert = 0.0,[]
	for i,vgrup in enumerate(set_vert.values()):
		v = vgrup[0]
		tan,lensum = mathutils.Vector((0,0,0)),0.0
		for v2 in vgrup:
			f = v2.face
			ind = f.v.index(v2.vert)
			f.vi[ind] = i
			wes = f.wes[ind]
			lensum += wes * f.ta.length
			tan += wes * f.ta
		assert lensum > 0.0
		avg += tan.length / lensum
		tan.normalize() # mean tangent
		no = v.normal
		no.normalize()
		bit = no.cross(tan) * v.face.hand   # using handness
		tan = bit.cross(no) # handness will be applied in shader
		tbn = mathutils.Matrix(tan, bit, no) # tbn is orthonormal, right-handed
		v.quat = tbn.to_quat().normalize()
		ar_vert.append(v)
	print("\t(i) %.2f avg tangent accuracy" % (avg / len(ar_vert)))
	del set_vert

	# 4: unlock quaternions to make all the faces QI-friendly
	def qi_check(f):	# check Quaternion Interpolation friendliness
		qx = tuple( ar_vert[x].quat for x in f.vi )
		assert qx[0].dot(qx[1]) >= 0 and qx[0].dot(qx[2]) >= 0
	def mark_used(ind):	# mark quaternion as used
		v = ar_vert[ind]
		if v.dual < 0: v.dual = ind
	n_dup,ex_face = 0,[]
	for f in (ar_face if st.doQuatInt else []):
		vx,cs,pos,n_neg = (1,2,0),[0,0,0],0,0
		def isGood(j):
			ind = f.vi[j]
			vi = ar_vert[ind]
			if vi.dual == ind: return False	# used, no clone
			if vi.dual < 0: vi.quat.negate()	# not used
			else:   f.vi[j] = vi.dual	# clone exists
			return True
		def duplicate():
			src = ar_vert[ f.vi[pos] ]
			dst = Vertex(src.vert)
			dst.face = f
			dst.tex = tuple( layer.copy() for layer in src.tex )
			dst.quat = src.quat.copy().negate()
			dst.dual = f.vi[pos]
			f.vi[pos] = src.dual = len(ar_vert)
			ar_vert.append(dst)
			return 1
		for j in range(3):
			qx = tuple( ar_vert[f.vi[x]].quat for x in (vx[j],vx[vx[j]]) )
			cs[j] = qx[0].dot(qx[1])
			if cs[j] > cs[pos]: pos = j
			if(cs[j] < 0): n_neg += 1
		#print "\t %d: %.1f, %.1f, %.1f" % (pos,cs[0],cs[1],cs[2])
		if n_neg == 2 and not isGood(pos):   # classic duplication case
			n_dup += duplicate()
		if n_neg == 3:  # extremely rare case
			pos = next((j for j in range(3) if isGood(j)), -1)
			if pos < 0:
				pos = 1
				n_dup += duplicate()
			cs[vx[pos]] *= -1
			cs[vx[vx[pos]]] *= -1
			n_neg -= 2
		if n_neg == 1: # that's a bad case
			pos = min((x,j) for j,x in enumerate(cs))[1]
			# prepare
			ia,ib = vx[pos],vx[vx[pos]]
			va = ar_vert[ f.vi[ia] ]
			vb = ar_vert[ f.vi[ib] ]
			vc = ar_vert[ f.vi[pos] ]
			# create mean vertex
			v = Vertex( vc.vert )
			v.vert = va.vert
			v.vert2 = vb.vert
			n_dup += 1
			v.face = f
			v.coord = 0.5 * (va.coord + vb.coord)
			v.quat = va.quat + vb.quat
			v.quat.normalize()
			v.tex = tuple( 0.5*(a[0]+a[1]) for a in zip(va.tex,vb.tex) )
			# create additional face
			f2 = Face( f, mesh )
			mark_used( f.vi[ia] )	# caution: easy to miss case
			v.dual = f.vi[ia] = f2.vi[ib] = len(ar_vert)
			# it's mathematically proven that both faces are QI friendly now!
			ar_vert.append(v)
			ex_face.append(f2)
		# mark as used
		for ind in f.vi: mark_used(ind)

	if st.doQuatInt:
		print("\textra: %d vertices, %d faces" % (n_dup,len(ex_face)))
		ar_face += ex_face
		# run a check
		for f in ar_face: qi_check(f)
	del ex_face

	# 5: face indexes
	ar_face.sort(key = lambda x: x.mat)
	face_num = (len(mesh.materials)+1) * [0]
	for face in ar_face:
		face_num[face.mat] += 1
	print("\t(i) %d vertices, %d faces" % (len(ar_vert),len(ar_face)))
	print("\t(i) %.2f avg vertex usage" % (3.0*len(ar_face)/len(ar_vert)))
	out.begin('mesh')
	out.pack('H', len(ar_vert) )
	out.end()
	
	out.begin('v_pos')
	for v in ar_vert:
		out.pack('4f', v.coord.x, v.coord.y, v.coord.z, v.face.hand)
	out.end()
	out.begin('v_quat')
	for v in ar_vert:
		out.pack('4f', v.quat.x, v.quat.y, v.quat.z, v.quat.w)
	out.end()
	
	if st.putUv:
		all = mesh.uv_textures
		print("\t", 'UV layers:', len(all) )
		for i,layer in enumerate(all):
			out.begin('v_uv')
			out.text( layer.name )
			for v in ar_vert:
				assert i<len(v.tex)
				out.pack('2f', v.tex[i].x, v.tex[i].y)
			out.end()
	if st.putColor:
		all = mesh.vertex_colors
		print("\t", 'Color layers:', len(all) )
		for i,layer in enumerate(all):
			out.begin('v_color')
			out.text( layer.name )
			for v in ar_vert:
				assert i<len(v.color)
				save_color(v.color[i])
			out.end()

	out.begin('v_ind')
	out.pack('H', len(ar_face))
	for face in ar_face:
		out.array('H', face.vi)
	out.end()

	# 6: materials
	out.begin('entity')
	for fn,m in zip(face_num,mesh.materials):
		if not fn: break
		out.pack('H', fn)
		out.text( m.name )
		print("\t+entity: %d faces, [%s]" % (fn,m.name))
	out.pack('H',0)
	out.end()
	
	# 7: shape keys
	shapes = mesh.shape_keys
	for sk in (shapes.keys if shapes else []):
		print("\t+shape: %.3f [%s]" % (sk.value,sk.name))
		out.begin('v_shape')
		out.text( sk.name )
		out.pack('Bf', list(shapes).index(sk.relative_key), sk.value )
		for v in ar_vert:
			pos = sk.data[v.vert.index].co
			if v.vert2:
				p2 = sk.data[v.vert2.index].co
				pos = 0.5*(pos+p2)
			out.pack('3f', pos.x, pos.y, pos.z)
		out.end()

	# 8: bone weights
	if not armature: return
	out.begin('v_skin')
	nempty, avg = 0, 0.0
	for v in ar_vert:
		nw = len(v.vert.groups)
		avg += nw
		if not nw:
			nempty += 1
			array.array('H',[255,0,0,0]).tofile(file)
			continue
		bone = sorted(v.vert.groups, key=lambda x: x.weight, reverse=True) [:min(4,nw)]
		left, total = 255, sum(b.weight for b in bone)
		for i in range(4):
			bid,weight = 0,0
			if i < len(bone):
				name = groups[ bone[i].group ].name
				bid = armature.bones.keys().index(name) + 1
				weight = int(255.0 * bone[i].weight / total + 0.5)
			if i==3: weight = left
			else: weight = min(left,weight)
			left -= weight
			assert weight>=0 and weight<256
			out.pack('2B', weight,bid)
	avg /= len(ar_vert)
	out.end()
	print("\tbone weights: %d empty, %.1f avg" % (nempty,avg))


###  LIGHT & CAMERA   ###

def save_lamp(lamp):
	energy_threshold = 0.1
	print("\t(i) %s type, %.1f distance" % (lamp.type, lamp.distance))
	out.begin('lamp')
	save_color( lamp.color )
	if not lamp.specular or not lamp.diffuse:
		print("\t(w)",'specular/diffuse cant be disabled')
	clip0,clip1,spotAng,spotBlend = 1.0,2.0*lamp.distance,0.0,0.0
	# attenuation
	kd = 1.0 / lamp.distance
	q0,q1,q2,qs = lamp.energy, kd, kd*kd, 0.0
	if lamp.type in ('POINT','SPOT'):
		if lamp.sphere:
			print("\t(i) spherical limit")
			clip1 = lamp.distance
			qs = kd
		ft = lamp.falloff_type
		if ft == 'LINEAR_QUADRATIC_WEIGHTED':
			q1 *= lamp.linear_attenuation
			q2 *= lamp.quadratic_attenuation
		elif ft == 'INVERSE_LINEAR': q2=0.0
		elif ft == 'INVERSE_SQUARE': q1=0.0
		elif ft == 'CONSTANT': q1=q2=0.0
		else: print("\t(w) custom curve is not supported")
		print("\tfalloff: %s, %.4f q1, %.4f q2" % (ft,q1,q2))
	else: q1=q2=0.0
	out.pack('4f', q0,q1,q2,qs)
	if lamp.type == 'SPOT':
		spotAng,spotBlend = lamp.spot_size,lamp.spot_blend
	out.text( lamp.type )
	out.pack('4f', clip0,clip1, spotAng,spotBlend )
	out.end()


def save_camera(cam, is_cur):
	if is_cur: print("\t(i) active")
	fov = cam.angle
	if cam.type == 'ORTHO':
		scale = cam.ortho_scale
		print("\t(i) ortho scale: %.2f" % (scale))
		fov = -4.0 / scale	# will be scaled by 0.5 on reading
	print("\t%s, dist: [%.2f-%.2f], fov: %.2f" % (
		('A' if is_cur else '_'),
		cam.clip_start, cam.clip_end, fov) )
	out.begin('cam')
	out.pack('B3f', is_cur,
		cam.clip_start, cam.clip_end, fov)
	out.end()


###	SKELETON:CORE		###

def save_skeleton(skel):
	out.begin('skel')
	nbon = len(skel.bones)
	print("\t(i)", nbon ,'bones')
	out.pack('B', nbon)
	for bone in skel.bones:
		parid,par,mx = -1, bone.parent, bone.matrix_local.copy()
		if not (bone.inherit_scale and bone.deform):
			print("\t\t(w)", 'weird bone', bone.name)
		if par: # old variant (same result)
			#pos = bone.head.copy() + par.matrix.copy().invert() * par.vector	
			parid = skel.bones.keys().index( par.name )
			mx = par.matrix_local.copy().invert() * mx
		out.text( bone.name )
		out.pack('B', parid+1 )
		save_matrix(mx)
	out.end()


###	PARTICLES	###

def save_particle(obj,part):
	st = part.settings
	life = (st.frame_start, st.frame_end, st.lifetime)
	mat = obj.material_slots[ st.material-1 ].material
	matname = (mat.name if mat else '')
	info = (part.name, matname, st.amount)
	print("\t+particle: %s [%s], %d num" % info )
	out.begin('part')
	out.pack('L', st.amount)
	out.text( part.name, matname )
	out.end()

	if st.type == 'HAIR' and not part.cloth:
		print("\t(w)",'hair dynamics has to be enabled')
	elif st.type == 'HAIR' and part.cloth:
		if not mat.strand.blender_units:
			print("\t(w)",'material strand size in units required')
		cset = part.cloth.settings
		print("\t\thair: %d segments" % (st.hair_step,) )
		out.begin('p_hair')
		out.pack('B3f2f', st.hair_step,
			cset.pin_stiffness, cset.mass, cset.bending_stiffness,
			cset.spring_damping, cset.air_damping )
		out.end()
	elif st.type == 'EMITTER':
		print("\t\temitter: [%d-%d] life %d" % life)
		out.begin('p_life')
		out.array('f', [x*kFrameSec for x in life] )
		out.pack('f', st.random_lifetime )
		out.end()
	
	if st.ren_as == 'OBJECT':
		print("\t\t(i)", 'instanced', st.dupli_object )
		out.begin('pr_inst')
		out.text( st.dupli_object.name )
		out.end()
	elif st.ren_as == 'LINE':
		out.begin('pr_line')
		out.pack('B2f', st.velocity_length,
			st.line_length_tail, st.line_length_head )
		out.end()
	elif not st.ren_as in ('HALO','PATH'):
		print("\t\t(w)", 'render as unsupported:', st.ren_as )
	
	out.begin('p_vel')
	out.array('f', st.object_aligned_factor )
	out.pack('3f', st.normal_factor, st.tangent_factor, st.tangent_phase )
	out.pack('2f', st.object_factor, st.random_factor )
	out.end()

	if st.emit_from == 'FACE' and not obj.data.active_uv_texture:
		print("\t\t(w)",'emitter surface does not have UV')
	out.begin('p_dist')
	out.text( st.emit_from, st.distribution )
	out.pack('f', st.jitter_factor )
	out.end()
	out.begin('p_rot')
	out.text( st.angular_velocity_mode )
	out.pack('f', st.angular_velocity_factor )
	out.end()
	out.begin('p_phys')
	out.pack('2f3f', st.particle_size, st.random_size,
		st.brownian_factor, st.drag_factor, st.damp_factor )
	out.end()


###  	GAME OBJECT	###

def save_game(gob):
	flag = (gob.actor, not gob.ghost)
	if	gob.physics_type == 'STATIC':
		out.begin('b_stat')
		out.array('B',flag)
		out.end()
	elif	gob.physics_type == 'RIGID_BODY':
		out.begin('b_rigid')
		out.array('B',flag)
		out.pack('3f2f', gob.mass, gob.radius, gob.form_factor,
			gob.damping, gob.rotation_damping )
		out.end()
	if gob.use_collision_bounds:
		print("\t(i)", 'collision', gob.collision_bounds)
		out.begin('collide')
		out.pack('f', gob.collision_margin )
		out.text( gob.collision_bounds )
		out.end()

###  	NODE:CORE	###

def save_node(ob):
	print(ob.type, ob.name, ob.parent)
	# todo: parent types (bone,armature,node)
	out.begin('node')
	par_name = (ob.parent.name if ob.parent else '')
	out.text( ob.name, par_name )
	save_matrix( ob.matrix_local )
	out.end()


### 	 SCENE		###

def save_scene(filename, context, st):
	import time
	global out,file_ext,bDegrees
	timeStart = time.clock()
	print("\nExporting...")
	if not filename.lower().endswith(file_ext):
		filename += file_ext
	out = Writer(filename)
	out.begin('kri')
	out.pack('B',3)
	out.end()
	
	sc = context.scene
	bDegrees = (sc.unit_settings.rotation_units == 'DEGREES')
	if not bDegrees:
		#it's easier to convert on loading than here
		print("\t(w)",'Radians are not supported')
	if sc.use_gravity:
		print("\tgravity:", sc.gravity)
		out.begin('grav')
		out.array('f', sc.gravity)
		out.end()
	
	for mat in context.main.materials:
		save_mat(mat)
		save_actions( mat, 'm','t' )

	for ob in sc.objects:
		save_node( ob )
		save_actions( ob, 'n', None )
		save_game( ob.game )

		if ob.type == 'MESH':
			arm = None
			if ob.parent and ob.parent.type == 'ARMATURE':
				arm = ob.parent.data
			save_mesh( ob.data, arm, ob.vertex_groups, st )
			save_actions( ob.data.shape_keys, '','v' )
		elif ob.type == 'ARMATURE':
			save_skeleton( ob.data )
			save_actions( ob.data, None, 's' )
		elif ob.type == 'LAMP':
			save_lamp( ob.data )
			save_actions( ob.data, 'l','' )
		elif ob.type == 'CAMERA':
			save_camera( ob.data, ob == sc.camera )
			save_actions( ob.data, 'c','' )
		for p in ob.particle_systems:
			save_particle(ob,p)
	print('Done.')
	out.fx.close()
	print('Export time:', time.clock()-timeStart)


### 	 EXPORT MODULE		###

class ExportKRI( bpy.types.Operator ):
	''' Export to KRI scene format (.scene).'''
	from bpy.props	import StringProperty,BoolProperty
	
	bl_idname = 'export.kri_scene'
	bl_label = 'Export KRI'
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
	
	def invoke(self, context, event):
		context.manager.add_fileselect(self)
		return {'RUNNING_MODAL'}
	
	def poll(self, context):
		return context.active_object


# Add to a menu
def menu_func(self, context):
	import os
	default_path = os.path.splitext( bpy.data.filepath )[0] + file_ext
	self.layout.operator(ExportKRI.bl_idname, text='Scene KRI...').filepath = default_path

def register():
    bpy.types.register(ExportKRI)
    bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
    bpy.types.unregister(ExportKRI)
    bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == "__main__":
    register()
