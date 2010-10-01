namespace kri.load

import System.Collections.Generic
import kri.meta
import OpenTK
import OpenTK.Graphics


public class ExMaterial( kri.IExtension ):
	public final limDict	= Dictionary[of string,callable(Reader) as Hermit]()
	public final con		= Context()
	public prefix	as string	= 'res'
	# texture target name -> (meta name, shader)
	public final tarDict = Dictionary[of string,MapTarget]()

	public struct MapTarget:
		public final name	as string
		public final prog	as kri.shade.Object
		public def constructor(s as string, p as kri.shade.Object):
			name,prog = s,p
	
	def kri.IExtension.attach(nt as Native) as void:
		init()
		# fill targets
		tarDict['color_diffuse']	= MapTarget('diffuse',	con.slib.diffuse_t2 )
		tarDict['color_emission']	= MapTarget('emissive',	con.slib.emissive_t2 )
		# material
		nt.readers['mat']		= p_mat
		nt.readers['m_hair']	= pm_hair
		nt.readers['m_halo']	= pm_halo
		nt.readers['m_surf']	= pm_surf
		nt.readers['m_emis']	= pm_emis
		nt.readers['m_diff']	= pm_diff
		nt.readers['m_spec']	= pm_spec
		nt.readers['unit']		= pm_unit
		nt.readers['t_map']		= pt_map
		nt.readers['t_samp']	= pt_samp
		nt.readers['t_path']	= pt_path
		nt.readers['t_seq']		= pt_seq
		nt.readers['t_color']	= pt_color
		nt.readers['t_ramp']	= pt_ramp
		nt.readers['t_noise']	= pt_noise
		nt.readers['t_blend']	= pt_blend
	
	
	private def init() as void:
		uvShaders = [	kri.shade.Object.Load("/mi/uv${i}_v") for i in range(4) ]
		orcoVert =	kri.shade.Object.Load('/mi/orco_v')
		orcoHalo =	kri.shade.Object.Load('/mi/orco_halo_f')
		objectShader = 	kri.shade.Object.Load('/mi/object_v')
		# todo?: normal & reflection in fragment
		# trivial sources
		def genFun(x as Hermit): return {return x}
		for s in ('GLOBAL','WINDOW','NORMAL','REFLECTION','TANGENT','STRAND'):
			slow = s.ToLower()
			suf = 'v'
			suf = 'f'	if s == 'WINDOW'
			suf = 'g'	if s == 'STRAND'
			sh = kri.shade.Object.Load( "/mi/${slow}_${suf}" )
			mt = Hermit( Shader:sh, Name:slow )	# careful!
			limDict[s] = genFun(mt)
		# non-trivial sources
		limDict['UV']		= do(r as Reader):
			lid = r.getByte()
			return Hermit( Shader:uvShaders[lid],	Name:'uv'+lid )
		limDict['ORCO']		= do(r as Reader):
			mat = r.geData[of kri.Material]()
			assert mat
			r.getString()	# mapping type, not supported
			sh = (orcoVert,orcoHalo)[ mat.Meta['halo'] != null ]
			return Hermit( Shader:sh, Name:'orco' )
		limDict['OBJECT']	= do(r as Reader):
			mio = InputObject( Shader:objectShader,	Name:'object' )
			r.addResolve( mio.pNode.activate )
			return mio
	

	#---	Parse texture unit	---#
	
	public def pm_unit(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		# map targets
		u = AdUnit()
		m.unit.Add(u)
		r.puData(u)
		while (name = r.getString()) != '':
			targ as MapTarget
			continue if not tarDict.TryGetValue(name,targ)
			me = m.Meta[targ.name] as Advanced
			continue	if not me
			me.Unit = m.unit.IndexOf(u)
			me.Shader = targ.prog
		# map inputs
		name = r.getString()
		fun as callable(Reader) as Hermit = null
		if limDict.TryGetValue(name,fun):
			u.input = fun(r)
			return true
		return false


	#---	Parse material	---#
	public def p_mat(r as Reader) as bool:
		m = kri.Material( r.getString() )
		r.at.mats[m.name] = m
		r.puData(m)
		r.addPostProcess() do(n as kri.Node):
			m.link()
		return true

#---	Strand properties	---#
	public def pm_hair(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		ms = Strand( Name:'strand', Data:r.getVec4() )
		r.getByte()	# tangent shading
		ms.Shader = con.slib.strand_u
		m.metaList.Add(ms)
		return true
	
	#---	Halo properties		---#
	public def pm_halo(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		mh = Halo( Name:'halo', Data:Vector4(r.getVector()) )
		r.getByte()	# use texture - ignored
		mh.Shader = con.slib.halo_u
		m.metaList.Add(mh)
		return true
	
	#---	Surface properties	---#
	public def pm_surf(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		r.getByte()	# shadeless
		r.getReal()	# parallax
		m.metaList.Add( Advanced( Name:'bump', Shader:con.slib.bump_c ))
		r.getReal()	# ambient
		r.getReal()	# translucency
		return true
	
	#---	Meta: emissive	---#
	public def pm_emis(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		color = r.getColorFull()
		m.metaList.Add( Data[of Color4]('emissive',
			con.slib.emissive_u, color ))
		return true
	
	#---	Meta: diffuse	---#
	public def pm_diff(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		color = r.getColorFull()
		m.metaList.Add( Data[of Color4]('diffuse',
			con.slib.diffuse_u,	color ))
		model = r.getString()
		sh = { '':		con.slib.lambert,
			'LAMBERT':	con.slib.lambert
			}[model]
		assert sh and 'unknown diffuse model!'
		m.metaList.Add(Advanced( Name:'comp_diff', Shader:sh ))	if sh
		return true

	#---	Meta: specular	---#
	public def pm_spec(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		m.metaList.Add( Data[of Color4]('specular',
			con.slib.specular_u,	r.getColorFull() ))
		m.metaList.Add( Data[of single]('glossiness',
			con.slib.glossiness_u,	r.getReal() ))
		model = r.getString()
		sh = {
			'COOKTORR':	con.slib.cooktorr,
			'PHONG':	con.slib.phong,
			'BLINN':	con.slib.phong	#fake
			}[model]
		assert sh and 'unknown specular model!'
		m.metaList.Add( Advanced( Name:'comp_spec', Shader:sh ))
		return true

	#---	Texture: mapping	---#
	public def pt_map(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		# tex-coords
		u.pOffset.Value	= Vector4(r.getVector(), 0.0)
		u.pScale.Value	= Vector4(r.getVector(), 1.0)
		return true

	#---	Texture: sampling	---#
	public def pt_samp(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		bRepeat	= r.getByte()>0	# extend by repeat
		bMipMap	= r.getByte()>0	# generate mip-maps
		bFilter	= r.getByte()>0	# linear filtering
		# init sampler parameters, todo: use sampler object
		assert u.Value
		u.Value.setState( (0,1)[bRepeat], bFilter, bMipMap )
		return true

	#---	Texture: file path	---#
	public def pt_path(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		path = prefix + r.getString()
		u.Value = r.data.load[of kri.Texture](path)
		return u.Value != null

	#---	Texture: sequence	---#
	public def pt_seq(r as Reader) as bool:
		return false

	#---	Texture: color		---#
	public def pt_color(r as Reader) as bool:
		r.getColor()	# factor
		r.getReal()	# brightness
		r.getReal()	# contrast
		r.getReal()	# saturation
		return false
	
	#---	Texture: color ramp		---#
	public def pt_ramp(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		r.getString()	# interpolator
		num = r.getByte()
		data = array[of kri.gen.Texture.Key](num)
		for i in range(num):
			data[i].pos = r.getReal()
			data[i].col = r.getColor()
			data[i].col.A = r.getReal()
		u.Value = kri.gen.Texture.ofCurve(data)
		return u.Value != null

	#---	Texture: noise		---#
	public def pt_noise(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		u.Value = kri.gen.Texture.noise
		return true

	#---	Texture: blend		---#
	public def pt_blend(r as Reader) as bool:
		r.getString()	# interpolator
		r.getByte()		# flip_axis
		return true
