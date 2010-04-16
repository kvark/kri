namespace kri.load

import kri.meta
import OpenTK.Graphics

public partial class Native:
	public final limdic			= Dictionary[of string,callable() as Hermit]()
	private final nodeResolve	= Dictionary[of string,callable(kri.Node)]()

	public def initMaterials() as void:
		uvShaders = [	kri.shade.Object("/mi/uv${i}_v") for i in range(4) ]
		orcoShader =	kri.shade.Object('/mi/orco_v')
		objectShader = 	kri.shade.Object('/mi/object_v')
		# trivial sources
		def genFun(x as Hermit): return {return x}
		for s in ('GLOBAL','WINDOW','NORMAL','REFLECTION','TANGENT'):
			slow = s.ToLower()
			sh = kri.shade.Object( "/mi/${slow}_v" )
			mt = Hermit( Shader:sh, Name:slow )	# careful!
			limdic[s] = genFun(mt)
		# non-trivial sources
		limdic['UV'] = do():
			lid = br.ReadByte()
			return Hermit( Shader:uvShaders[lid],	Name:'uv'+lid )
		limdic['ORCO'] = do():
			getString()	# mapping type, not supported
			return Hermit( Shader:orcoShader,		Name:'orco' )
		limdic['OBJECT'] = do():
			name = getString()
			mio = InputObject( Shader:objectShader,	Name:'object' )
			nodeResolve[name] = mio.pNode.activate
			return mio
	
	public def finishMaterials() as void:
		for m in at.mats.Values:
			m.link()
			# pass material texture to halo if needed
			h  = m.Meta['halo']			as kri.meta.Halo
			md = m.Meta['diffuse']	as kri.meta.Data[of Color4]
			continue if not h or not md
			h.Color = md.Value
			if h.Shader == con.slib.halo_t2 and md.Unit:
				h.Tex = md.Unit.Value
		# resolve node links
		for nr in nodeResolve:
			nr.Value( at.nodes[nr.Key] )
		nodeResolve.Clear()


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
		u as AdUnit = null
		while (name = getString()) != '':
			targ as MapTarget
			continue if not tarDict.TryGetValue(name,targ)
			u = AdUnit(targ.name)	if not u
			me = m.Meta[targ.name] as Advanced
			continue	if not me
			me.Unit = u
			me.Shader = targ.prog
		# map inputs
		u = AdUnit(null)	if not u
		puData(u)
		name = getString()
		fun as callable() as Hermit = null
		if limdic.TryGetValue(name,fun):
			u.input = fun()
			return true
		return false


	#---	Parse material	---#
	public def p_mat() as bool:
		m = kri.Material( getString() )
		at.mats[m.name] = m
		puData(m)
		return true
	
	#---	Halo properties		---#
	public def pm_halo() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		mh = Halo( Name:'halo', Data:Vector4(getVector()) )
		mh.Shader = (con.slib.halo_u, con.slib.halo_t2)[ br.ReadByte() ]
		m.metaList.Add(mh)
		return true
	
	#---	Surface properties	---#
	public def pm_surf() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		br.ReadByte()	# shadeless
		getReal()		# parallax
		m.metaList.Add(Advanced( Name:'bump', Shader:con.slib.bump_c ))
		m.metaList.Add(memi = Data[of single]('emissive'))
		memi.Shader = con.slib.emissive_u
		memi.Value = getReal()
		getReal()	# ambient
		getReal()	# translucency
		return true
	
	#---	Meta: diffuse	---#
	public def pm_diff() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		m.metaList.Add(mdif = Data[of Color4]('diffuse'))
		mdif.Value = getColorFull()
		mdif.Shader = con.slib.diffuse_u
		sh = { '': null,
			'LAMBERT':	con.slib.lambert
			}[ getString() ]
		m.metaList.Add(Advanced( Name:'comp_diff', Shader:sh ))	if sh
		return true

	#---	Meta: specular	---#
	public def pm_spec() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		mspec = Data[of Color4]('specular')
		mspec.Shader = con.slib.specular_u
		mspec.Value = getColorFull()
		mglos = Data[of single]('glossiness')
		mglos.Shader = con.slib.glossiness_u
		mglos.Value = getReal()
		mcomp = Advanced( Name:'comp_spec' )
		mcomp.Shader = {
			'COOKTORR':	con.slib.cooktorr,
			'PHONG':	con.slib.phong
			}[ getString() ]
		m.metaList.AddRange((mspec,mglos,mcomp))
		return true

	
	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return null	if not str.EndsWith('.tga')
		return image.Targa(str).Result.generate()
	
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
