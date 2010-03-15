# coding: utf-8
__author__ = ['Dmitry Malyshev']
__url__ = ('kvgate.com')
__version__ = '0.5'
__bpydoc__ = '''KRI scene exporter.
This script exports the whole scene to the scene binary file.
'''

''' Math notes:
 The multiplication order is Matrix * vector
 Matrix[3] is the translation component
 Only right-handed matrix should be converted to quaternion
'''

import bpy
import struct,array
import math
file_ext = '.scene'
out = None
kFrameSec = 1.0 / 25.0
kMaxBones = 100

class Writer:
	__slots__= 'fx','pos'
	def __init__(self,path):
		self.fx = open(path,'wb')
		self.pos = 0
	def pack(self,tip,*args):
		assert self.pos
		self.fx.write( struct.pack(tip,*args) )
	def array(self,tip,ar):
		assert self.pos
		array.array(tip,ar).tofile(self.fx)
	def begin(self,name):
		assert len(name)<8 and not self.pos
		self.fx.write( struct.pack('<8sL',name,0) )
		self.pos = self.fx.tell()
	def end(self):
		assert self.pos
		off = self.fx.tell() - self.pos
		self.fx.seek(-off-4,1)
		self.fx.write( struct.pack('<L',off) )
		self.fx.seek(+off+0,1)
		self.pos = 0

def save_color(rgb, a, kf):
	for c in list(rgb)+[a]:
		out.pack( '<B', int(255*c*kf) )

def save_matrix(mx):
	#for i in range(4):
	#   array.array('f',mx[i]).tofile(file)
	pos = mx.translation_part()
	sca = mx.scale_part()
	rot = mx.to_quat()
	scale = (sca.x + sca.y + sca.z)/3.0
	if math.fabs(sca.x-sca.y) + math.fabs(sca.x-sca.z) > 0.01:
		print("\t(w)",'non-uniform scale:',str(sca))
	out.pack( '<8f',
		pos.x, pos.y, pos.z, scale,
		rot.x, rot.y, rot.z, rot.w)


###  MATERIAL   ###

def save_mat(mat):
	print("[%s]" % (mat.name))
	out.begin('mat')
	out.pack( '<24s', mat.name )
	save_color(mat.diffuse_color, 1.0, mat.emit)	#emissive
	save_color(mat.diffuse_color, mat.alpha, 1.0)   #diffuse
	save_color(mat.specular_color, mat.specular_alpha, 1.0) #specular
	sh = (mat.diffuse_shader, mat.specular_shader)
	print("\tshading: %s %s" % sh)
	out.pack( '<2B4f',
		('LAMBERT',).index(sh[0]), #cut off other types support
		('COOKTORR','PHONG').index(sh[1]),
		mat.diffuse_intensity, mat.specular_intensity,
		mat.specular_hardness, mat.ambient )
	out.end()
	for mtex in mat.texture_slots:
		tip,img = 0,None
		if mtex != None:
			ar = [mtex.map_colordiff, mtex.map_normal, mtex.map_coloremission,
				mtex.map_colorspec, mtex.map_colorreflection]
			if True in ar:  tip = 1 + ar.index(True)	# stupid python
			if mtex.texture and mtex.texture.type == 'IMAGE':
				img = mtex.texture.image
			else:	print("\t\t(w)",'tex type is not IMAGE')
		if not img: tip = 0
		if tip == 0: continue
		tc,mp = mtex.texture_coordinates, mtex.mapping
		print("\ttexture: %d domain, %s coords, %s mapping" % (tip,tc,mp))
		out.begin('tex')
		it = mtex.texture
		out.pack( '<6B', tip,
			('TANGENT','REFLECTION','NORMAL','WINDOW','UV','OBJECT','GLOBAL').index(tc),
			('SPHERE','TUBE','CUBE','FLAT').index(mp),
			('CLIP','REPEAT').index( it.extension ),
			it.mipmap, it.interpolation)
		name = img.filename
		print("\t\timage: ", name)
		out.pack( '<64s', name )
		out.end()


###  MESH   ###

def save_mesh(mesh,armature,groups,doQuatInt):
	import Mathutils as Math
	def calc_TBN(verts, uvs):
		va = verts[1].co - verts[0].co
		vb = verts[2].co - verts[0].co
		n1 = va.cross(vb)
		if uvs and n1.length > 0.0:
			ta = uvs[1] - uvs[0]
			tb = uvs[2] - uvs[0]
			assert ta.length + tb.length > 0.0
			tan = va*tb.y - vb*ta.y
			bit = vb*ta.x - va*tb.x
		else:
			tan = Math.Vector(1,0,0)
			bit = Math.Vector(0,1,0)
		# don't care about the length for now
		n0 = tan.cross(bit)
		hand = (-1.0 if n0.dot(n1) < 0.0 else 1.0)
		return (tan, bit, n0, hand, n1)

	class Vertex:
		__slots__= 'face', 'vert', 'coord', 'tex', 'normal', 'quat', 'dual'
		def __init__(self, v):
			self.face = None
			self.vert = v
			self.coord = v.co
			self.tex = None
			self.normal = v.normal
			self.quat = None
			self.dual = -1

	class Face:
		__slots__ = 'v', 'vi', 'no', 'uv', 'mat', 'ta', 'hand', 'normal', 'wes'
		def __init__(self, face, vs, ind = None, uves = None):
			if not ind: # clone KRI face
				self.vi = list(face.vi)
				self.hand = face.hand
				self.mat = face.mat
				return
			# warning: too many Vector constructors here - slow!
			# hint: try 'Recalculate Outside' if getting lighting problems
			self.mat = face.material_index
			self.vi = [ face.verts[i]	for i in ind   ]
			self.v  = [ vs[x]		for x in self.vi ]
			self.no = [ Math.Vector(x.normal)	for x in self.v  ]
			self.normal = Math.Vector(face.normal)
			if face.smooth: self.normal.zero()
			self.uv = [ Math.Vector(uves[i])	for i in ind ] if uves else None
			t,b,n,hand,nv = calc_TBN(self.v, self.uv)
			self.wes = 3 * [0.01+nv.length]
			assert t.length > 0.0
			self.ta = t.normalize()
			self.hand = hand
	
	#todo: support any UV layers
	uv_act = mesh.active_uv_texture
	if not uv_act: print("\t(w)",'no UV layers')

	#   1: convert Mesh to Triangle Mesh
	ar_face = []
	for i,face in enumerate(mesh.faces):
		uves,nvert = None,len(face.verts)
		if uv_act:
			d = uv_act.data[i]
			uves = (d.uv1,d.uv2,d.uv3,d.uv4)
		if nvert<3: continue
		ar_face.append( Face(face, mesh.verts, [0,1,2], uves) )
		if nvert<4: continue
		ar_face.append( Face(face, mesh.verts, [0,2,3], uves) )
	print("\tconverted to tri-mesh")

	#   2: fill sparsed vertex array
	avg,set_vert = 0.0,{}
	for face in ar_face:
		avg += face.hand
		for i in range(3):
			v = Vertex(face.v[i])
			if face.normal.length > 0.1:
				v.normal = face.normal
			else:   v.normal = face.no[i]
			if face.uv:
				v.tex = face.uv[i]
			else:   v.tex = None
			v.face = face
			vs = str((v.coord,v.tex,v.normal,face.hand))
			if not vs in set_vert:
				set_vert[vs] = []
			set_vert[vs].append(v)
	print("\t(i) %.2f avg handness" % (avg / len(ar_face)))
	
	#   3: update triangle indexes
	avg,ar_vert = 0.0,[]
	for i,vgrup in enumerate(set_vert.values()):
		v = vgrup[0]
		tan,lensum = Math.Vector(0,0,0),0.0
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
		tbn = Math.Matrix(tan, bit, no) # tbn is orthonormal, right-handed
		v.quat = tbn.to_quat().normalize()
		ar_vert.append(v)
	print("\t(i) %.2f avg tangent accuracy" % (avg / len(ar_vert)))
	del set_vert

	#   4: unlock quaternions to make all the faces QI-friendly
	def qi_check(f):	# check Quaternion Interpolation friendliness
		qx = [ar_vert[x].quat for x in f.vi]
		assert qx[0].dot(qx[1]) >= 0 and qx[0].dot(qx[2]) >= 0
	def mark_used(ind):	# mark quaternion as used
		v = ar_vert[ind]
		if v.dual < 0: v.dual = ind
	n_dup,ex_face = 0,[]
	for f in (ar_face if doQuatInt else []):
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
			dst.tex = src.tex.copy()
			dst.quat = src.quat.copy().negate()
			dst.dual = f.vi[pos]
			f.vi[pos] = src.dual = len(ar_vert)
			ar_vert.append(dst)
			return 1
		for j in range(3):
			qx = [ar_vert[f.vi[x]].quat for x in (vx[j],vx[vx[j]])]
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
			n_dup += 1
			v.face = f
			v.coord = 0.5 * (va.coord + vb.coord)
			v.quat = va.quat + vb.quat
			v.quat.normalize()
			v.tex = 0.5 * (va.tex + vb.tex)
			# create additional face
			f2 = Face(f, mesh.verts)
			mark_used(f.vi[ia])	# caution: easy to miss case
			v.dual = f.vi[ia] = f2.vi[ib] = len(ar_vert)
			# it's mathematically proven that both faces are QI friendly now!
			ar_vert.append(v)
			ex_face.append(f2)
		# mark as used
		for ind in f.vi: mark_used(ind)

	if doQuatInt:
		print("\textra: %d vertices, %d faces" % (n_dup,len(ex_face)))
		ar_face += ex_face
		# run a check
		for f in ar_face: qi_check(f)
	del ex_face

	#   5: face indexes
	ar_face.sort(key = lambda x: x.mat)
	face_num = (len(mesh.materials)+1) * [0]
	for face in ar_face:
		face_num[face.mat] += 1
	print("\t(i) %d vertices, %d faces" % (len(ar_vert),len(ar_face)))
	print("\t(i) %.2f avg vertex usage" % (3.0*len(ar_face)/len(ar_vert)))
	out.begin('mesh')
	out.pack('<H', len(ar_vert) )
	out.end()
	out.begin('v_pos')
	for v in ar_vert:
		out.pack('<3f', v.coord.x, v.coord.y, v.coord.z)
	out.end()
	out.begin('v_quat')
	for v in ar_vert:
		out.pack('<4f', v.quat.x, v.quat.y, v.quat.z, v.quat.w)
	out.end()
	if uv_act:
		out.begin('v_uv')
		for v in ar_vert:
			out.pack('<3f', v.tex.x, v.tex.y, v.face.hand)
		out.end()
	
	out.begin('v_ind')
	out.pack('<H', len(ar_face))
	for face in ar_face:
		out.array('H', face.vi)
	out.end()

	#   6: materials
	out.begin('entity')
	for fn,m in zip(face_num,mesh.materials):
		out.pack('<H24s', fn, m.name)
		print("\tentity: %d faces, [%s]" % (fn,m.name))
	out.pack('<H',0)
	out.end()

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
			out.pack('<2B', weight,bid)
	avg /= len(ar_vert)
	out.end()
	print("\tbone weights: %d empty, %.1f avg" % (nempty,avg))


###  LIGHT & CAMERA   ###

def save_lamp(lamp):
	energy_threshold = 0.1
	print("\t(i) %s type, %.1f distance" % (lamp.type, lamp.distance))
	out.begin('lamp')
	tip = ('POINT','SUN','SPOT','HEMI','AREA').index(lamp.type)
	save_color(lamp.color, 1.0,1.0)
	if not lamp.specular or not lamp.diffuse:
		print("\t(w) specular or diffuse can't be disabled")
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
	out.pack('<4f', q0,q1,q2,qs)
	if lamp.type == 'SPOT':
		spotAng,spotBlend = lamp.spot_size,lamp.spot_blend
	out.pack('<B4f', tip, clip0,clip1, spotAng,spotBlend )
	out.end()


def save_camera(cam, is_cur):
	if is_cur: print("\t(i) active")
	print("\t%s, dist: [%.2f-%.2f], fov: %.2f" % (
		('A' if is_cur else '_'), cam.clip_start,
		cam.clip_end, cam.angle) )
	out.begin('cam')
	out.pack('<B3f', is_cur,
		cam.clip_start, cam.clip_end,
		cam.angle)
	out.end()


###	SKELETON:ACTION		###

def save_action(act,skel):
	def save_ipo(ipos,offset):
		if None in ipos:
			out.pack('<H',0)
			return
		num = len( ipos[0].keyframe_points )
		#print "\t(i) %s, keys %d" %(ipo,num)
		for ip in ipos:
			assert len(ip.keyframe_points) == num
		out.pack('<H',num)
		for i in range(num):
			# hack: control_point is not documented in 2.5a0!
			x = (ipos[0].keyframe_points[i].co[0] - offset) * kFrameSec
			out.pack('<f',x)
			data = [ ip.keyframe_points[i].co[1] for ip in ipos ]
			out.array('f',data)
			#print ('Time', x, i, data)

	import re
	common = set(skel.bones.keys()).intersection( act.groups.keys() )
	nab = len(common) #number of animated joints
	offset,nf = act.get_frame_range()
	nf = nf+1-offset	# number of frames
	out.begin('act')
	out.pack( '<24sf', act.name, nf * kFrameSec )
	out.end()
	print("\tanim: '%s', %d frames, %d bones" % (act.name,nf,nab))
	assert nab
	rnas = {}
	for f in act.fcurves:
		mat = re.search('(\w+)\[\"(.+)\"\]\.(\w+)', f.data_path)
		key = mat.groups()
		assert key[0] == 'bones'
		tag = ('location','rotation_quaternion','scale').index(key[2])
		val = (tag<<2) + f.array_index
		if not (key[1] in rnas):
			rnas[key[1]] = 12 * [None]
		rnas[key[1]][val] = f
	for bn in common:
		out.begin('a_bone')
		out.pack('<B', skel.bones.keys().index(bn) )
		order = ((0,1,2),(5,6,7,4),(8,))
		for subord in order:
			ipos = list(rnas[bn][i] for i in subord)
			save_ipo(ipos,offset)
		out.end()
		#print('Bone ',bn)
		#save_ipo(chan, (Ipo.PO_LOCX, Ipo.PO_LOCY, Ipo.PO_LOCZ))
		#save_ipo(chan, (Ipo.PO_QUATX, Ipo.PO_QUATY, Ipo.PO_QUATZ, Ipo.PO_QUATW))
		#save_ipo(chan, (Ipo.PO_SCALEX,))

###	SKELETON:CORE		###

def save_skeleton(skel):
	out.begin('skel')
	nbon = len(skel.bones)
	assert nbon < kMaxBones
	print("\t(i)", nbon ,'bones')
	out.pack('<B', nbon)
	for bone in skel.bones:
		parid,par,mx = -1, bone.parent, bone.matrix_local.copy()
		if par: # old variant (same result)
			#pos = bone.head.copy() + par.matrix.copy().invert() * par.vector	
			parid = skel.bones.keys().index( par.name )
			mx = par.matrix_local.copy().invert() * mx
		out.pack( '<24sB', bone.name, parid+1 )
		save_matrix(mx)
	out.end()
	# export actions
	actions = []
	if skel.animation_data:
		actions = [ns.action for nt in skel.animation_data.nla_tracks for ns in nt.strips]
	else:
		names = set( skel.bones.keys() )
		def affects(a):
			n2 = set(gr.name for gr in a.groups)
			return not names.isdisjoint(n2)
		actions = [a for a in bpy.data.actions if affects(a)]
	for act in actions:
		save_action(act, skel)
		#for b in ob.getPose().bones.values():
		#   print b.name,b.poseMatrix


###	PARTICLES	###

def save_particle(part):
	st = part.settings
	assert st.type == 'EMITTER'
	life = (st.start, st.end, st.lifetime)
	add = (st.random_lifetime, st.tangent_phase)
	vel = (st.object_factor, st.normal_factor, st.tangent_factor,
		st.reactor_factor, st.particle_factor, st.random_factor)
	force = (st.brownian_factor, st.damp_factor, st.drag_factor)
	size = (st.particle_size, st.random_size)
	mat = bpy.data.materials[ st.material-1 ]
	matname = (mat.name if mat else '')
	print("\tparticle: %s [%s] %d num, [%d-%d] life %d" % ((part.name, matname, st.amount) + life))
	dist = ('JIT','RAND','GRID').index( st.distribution )
	out.begin('part')
	out.pack('<L24s24sBf', st.amount, part.name, matname, dist, st.jitter_factor)
	out.array('f', [x*kFrameSec for x in life] )
	obal = tuple( st.object_aligned_factor )
	out.array('f', add+vel+obal+force+size )
	out.end()


###  	GAME OBJECT	###

def save_game(gob):
	flag = (gob.actor, not gob.ghost)
	enum = (gob.physics_type, gob.collision_bounds)
	enu0 = ('NO_COLLISION','STATIC','DYNAMIC','RIGID_BODY','SOFT_BODY','OCCLUDE','SENSOR').index(enum[0])
	enu1 = ('BOX','SPHERE','CYLINDER','CONE','CONVEX_HULL','TRIANGLE_MESH').index(enum[1])
	phys = (gob.mass, gob.radius)
	damp = (gob.damping, gob.rotation_damping, gob.form_factor)
	frict = tuple(gob.friction_coefficients)
	out.begin('body')
	out.array('B', flag + (enu0,enu1) )
	out.array('f', phys + damp + frict)
	out.end()
	print("\t(i) %s physics, %s bounds, %.1f mass, %.1f radius" % (enum+phys))


###  	NODE	###
def save_node(ob):
	print(ob.type, ob.name, ob.parent)
	# todo: parent types (bone,armature,node)
	out.begin('node')
	par_name = (ob.parent.name if ob.parent else '')
	out.pack( '<24s24s', ob.name, par_name )
	# transform matrix world->local space
	local = (ob.matrix * ob.parent.matrix.copy().invert()) if ob.parent else ob.matrix
	save_matrix( local )
	out.end()
	

### 	 SCENE		###

def save_scene(filename, context, doQuatInt=True):
	print("\nExporting...")
	global out,file_ext
	if not filename.lower().endswith(file_ext):
		filename += file_ext
	out = Writer(filename)
	out.begin('kri')
	out.pack('<B',3)
	out.end()
	
	for mat in context.main.materials:
	   save_mat(mat)

	for ob in context.scene.objects:
		save_node( ob )
		save_game( ob.game )

		if ob.type == 'MESH':
			arm = None
			if ob.parent and ob.parent.type == 'ARMATURE':
				arm = ob.parent.data
			save_mesh(ob.data, arm, ob.vertex_groups, doQuatInt)
		elif ob.type == 'ARMATURE':
			save_skeleton(ob.data)
		elif ob.type == 'LAMP':
			save_lamp(ob.data)
		elif ob.type == 'CAMERA':
			save_camera(ob.data, ob == context.scene.camera)

		for p in ob.particle_systems:
			save_particle(p)
	print('Done.')
	out.fx.close()


class ExportKRI( bpy.types.Operator ):
	''' Export to KRI scene format (.scene).'''
	from bpy.props	import StringProperty
	bl_idname = 'export.scene_kri'
	bl_label = 'Export KRI'
	
	path = bpy.props.StringProperty(name='File Path', description='Export destination for KRI scene', maxlen=1024, default='')
	quat_int = bpy.props.BoolProperty(name="Process quaternions", description="Prepare mesh quaternions for interpolation", default=True)
	
	def execute(self, context):
		save_scene(self.properties.path, context,
			doQuatInt = self.properties.quat_int)
		return {'FINISHED'}
	
	def invoke(self, context, event):
		context.manager.add_fileselect(self)
		return {'RUNNING_MODAL'}
	
	def poll(self, context):
		return context.active_object

# Add to a menu
def menu_func(self, context):
	global file_ext
	default_path = bpy.data.filename.replace('.blend',file_ext)
	self.layout.operator(ExportKRI.bl_idname, text='Scene KRI...').path = default_path

def register():
    bpy.types.register(ExportKRI)
    bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
    bpy.types.unregister(ExportKRI)
    bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == "__main__":
    register()
