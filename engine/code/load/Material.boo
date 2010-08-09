namespace kri.load

import System.Collections.Generic
import kri.meta
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


public class ExMaterial( kri.IExtension ):
	public final limDict	= Dictionary[of string,callable(Reader) as Hermit]()
	public final con		= Context()
	public prefix	as string	= 'res'
	
	def kri.IExtension.attach(nt as Native) as void:
		init()
		# material
		nt.readers['mat']		= p_mat
		nt.readers['m_hair']	= pm_hair
		nt.readers['m_halo']	= pm_halo
		nt.readers['m_surf']	= pm_surf
		nt.readers['m_diff']	= pm_diff
		nt.readers['m_spec']	= pm_spec
		nt.readers['unit']		= pm_unit
		nt.readers['mt_map']	= pmt_map
		nt.readers['mt_samp']	= pmt_samp
		nt.readers['mt_path']	= pmt_path
		nt.readers['mt_seq']	= pmt_seq
	
	
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
	private struct MapTarget:
		public final name	as string
		public final prog	as kri.shade.Object
		public def constructor(s as string, p as kri.shade.Object):
			name,prog = s,p
	
	public def pm_unit(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		tarDict = Dictionary[of string,MapTarget]()
		tarDict['colordiff']		= MapTarget('diffuse',	con.slib.diffuse_t2 )
		tarDict['coloremission']	= MapTarget('emissive',	con.slib.emissive_t2 )
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
		r.getReal()		# parallax
		m.metaList.Add( Advanced( Name:'bump', Shader:con.slib.bump_c ))
		m.metaList.Add( Data[of single]('emissive',
			con.slib.emissive_u, r.getReal() ))
		r.getReal()	# ambient
		r.getReal()	# translucency
		return true
	
	#---	Meta: diffuse	---#
	public def pm_diff(r as Reader) as bool:
		m = r.geData[of kri.Material]()
		return false	if not m
		m.metaList.Add( Data[of Color4]('diffuse',
			con.slib.diffuse_u,	r.getColorFull() ))
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
	public def pmt_map(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		# tex-coords
		u.pOffset.Value	= Vector4(r.getVector(), 0.0)
		u.pScale.Value	= Vector4(r.getVector(), 1.0)
		return true

	#---	Texture: sampling	---#
	public def pmt_samp(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		bRepeat	= r.getByte()>0	# extend by repeat
		bMipMap	= r.getByte()>0	# generate mip-maps
		bFilter	= r.getByte()>0	# linear filtering
		# init sampler parameters, todo: use sampler object
		assert u.Value
		u.Value.bind()
		kri.Texture.Filter(bFilter,bMipMap)
		wm = (TextureWrapMode.ClampToBorder,TextureWrapMode.Repeat)[bRepeat]
		kri.Texture.Wrap(wm,2)
		kri.Texture.GenLevels()	if bMipMap
		return true

	#---	Texture: file path	---#
	public def pmt_path(r as Reader) as bool:
		u = r.geData[of AdUnit]()
		return false	if not u
		path = prefix + r.getString()
		u.Value = r.res.load[of kri.Texture](path)
		return u.Value != null

	#---	Texture: sequence	---#
	public def pmt_seq(r as Reader) as bool:
		return false
