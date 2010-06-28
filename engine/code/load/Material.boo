namespace kri.load

import kri.meta
import OpenTK.Graphics


public partial class Native:
	public final limDict	= Dictionary[of string,callable() as Hermit]()

	public def initMaterials() as void:
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
		limDict['UV'] = do():
			lid = br.ReadByte()
			return Hermit( Shader:uvShaders[lid],	Name:'uv'+lid )
		limDict['ORCO'] = do():
			mat = geData[of kri.Material]()
			assert mat
			getString()	# mapping type, not supported
			sh = (orcoVert,orcoHalo)[ mat.Meta['halo'] != null ]
			return Hermit( Shader:sh, Name:'orco' )
		limDict['OBJECT'] = do():
			mio = InputObject( Shader:objectShader,	Name:'object' )
			addResolve( mio.pNode.activate )
			return mio
	
	public def finishMaterials() as void:
		for m in at.mats.Values:
			m.link()


	#---	Parse texture unit	---#
	private struct MapTarget:
		public final name	as string
		public final prog	as kri.shade.Object
		public def constructor(s as string, p as kri.shade.Object):
			name,prog = s,p
	
	public def pm_unit() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		tarDict = Dictionary[of string,MapTarget]()
		tarDict['colordiff']		= MapTarget('diffuse',	con.slib.diffuse_t2 )
		tarDict['coloremission']	= MapTarget('emissive',	con.slib.emissive_t2 )
		# map targets
		u  = AdUnit()
		puData(u)
		while (name = getString()) != '':
			targ as MapTarget
			continue if not tarDict.TryGetValue(name,targ)
			me = m.Meta[targ.name] as Advanced
			continue	if not me
			me.Unit = u
			me.Shader = targ.prog
		# map inputs
		name = getString()
		fun as callable() as Hermit = null
		if limDict.TryGetValue(name,fun):
			u.input = fun()
			return true
		return false


	#---	Parse material	---#
	public def p_mat() as bool:
		m = kri.Material( getString() )
		at.mats[m.name] = m
		puData(m)
		return true
	
	#---	Strand properties	---#
	public def pm_hair() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		ms = Strand( Name:'strand', Data:getVec4() )
		br.ReadByte()	# tangent shading
		ms.Shader = con.slib.strand_u
		m.metaList.Add(ms)
		return true
	
	#---	Halo properties		---#
	public def pm_halo() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		mh = Halo( Name:'halo', Data:Vector4(getVector()) )
		br.ReadByte()	# use texture - ignored
		mh.Shader = con.slib.halo_u
		m.metaList.Add(mh)
		return true
	
	#---	Surface properties	---#
	public def pm_surf() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		br.ReadByte()	# shadeless
		getReal()		# parallax
		m.metaList.Add( Advanced( Name:'bump', Shader:con.slib.bump_c ))
		m.metaList.Add( Data[of single]('emissive',
			con.slib.emissive_u, getReal() ))
		getReal()	# ambient
		getReal()	# translucency
		return true
	
	#---	Meta: diffuse	---#
	public def pm_diff() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		m.metaList.Add( Data[of Color4]('diffuse',
			con.slib.diffuse_u,	getColorFull() ))
		model = getString()
		sh = { '':		con.slib.lambert,
			'LAMBERT':	con.slib.lambert
			}[model]
		assert sh and 'unknown diffuse model!'
		m.metaList.Add(Advanced( Name:'comp_diff', Shader:sh ))	if sh
		return true

	#---	Meta: specular	---#
	public def pm_spec() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		m.metaList.Add( Data[of Color4]('specular',
			con.slib.specular_u,	getColorFull() ))
		m.metaList.Add( Data[of single]('glossiness',
			con.slib.glossiness_u,	getReal() ))
		model = getString()
		sh = {
			'COOKTORR':	con.slib.cooktorr,
			'PHONG':	con.slib.phong,
			'BLINN':	con.slib.phong	#fake
			}[model]
		assert sh and 'unknown specular model!'
		m.metaList.Add( Advanced( Name:'comp_spec', Shader:sh ))
		return true

	
	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return null	if not str.EndsWith('.tga')
		return resMan.load[of image.Basic](str).generate()
	
	#---	Parse texture slot	---#
	public def pm_tex() as bool:
		u = geData[of AdUnit]()
		return false	if not u
		image.Basic.bRepeat	= br.ReadByte()>0	# extend by repeat
		image.Basic.bMipMap	= br.ReadByte()>0	# generate mip-maps
		image.Basic.bFilter	= br.ReadByte()>0	# linear filtering
		# texcoords & image path
		u.pOffset.Value	= Vector4(getVector(), 0.0)
		u.pScale.Value	= Vector4(getVector(), 1.0)
		u.Value = getTexture( 'res' + getString() )
		return u.Value != null
