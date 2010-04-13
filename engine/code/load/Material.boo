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
			mt = Hermit( shader:sh, Name:slow )	# careful!
			limdic[s] = genFun(mt)
		# non-trivial sources
		limdic['UV'] = do():
			lid = br.ReadByte()
			return Hermit( shader:uvShaders[lid],	Name:'uv'+lid )
		limdic['ORCO'] = do():
			getString()	# mapping type, not supported
			return Hermit( shader:orcoShader,		Name:'orco' )
		limdic['OBJECT'] = do():
			name = getString()
			mio = InputObject( shader:objectShader,	Name:'object' )
			nodeResolve[name] = mio.pNode.activate
			return mio
	
	public def finishMaterials() as void:
		for m in at.mats.Values:
			m.link()
			# pass material texture to halo if needed
			h = m.Meta['halo']	as kri.meta.Halo
			if h and h.shader == con.slib.halo_t2:
				md = m.Meta['diffuse'] as kri.meta.Data_Color4
				h.Color = md.Value		if md
				h.Tex = md.unit.Value	if md and md.unit
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
		u = AdUnit()
		puData(u)
		tarDict = Dictionary[of string,MapTarget]()
		tarDict['colordiff']		= MapTarget( 'diffuse',		con.slib.diffuse_t2 )
		tarDict['coloremission']	= MapTarget( 'emissive',	con.slib.emissive_t2 )
		# map targets
		while (name = getString()) != '':
			targ as MapTarget
			continue if not tarDict.TryGetValue(name,targ)
			u.Name = targ.name	if System.String.IsNullOrEmpty(u.Name)
			me = m.Meta[targ.name]
			continue	if not me
			me.unit = u
			me.shader = targ.prog
		# map inputs
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
		data = getVector()
		m.Meta['halo']	=h= Halo( Data:Vector4(data) )
		tex = br.ReadByte()
		h.shader = (con.slib.halo_u, con.slib.halo_t2)[tex]
		return true
	
	#---	Surface properties	---#
	public def pm_surf() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		br.ReadByte()	# shadeless
		getReal()		# parallax
		m.Meta['bump']		= Advanced( shader:con.slib.bump_c )
		emit = getReal()
		m.Meta['emissive']	= Data_single( shader:con.slib.emissive_u,	Value:emit )
		getReal()	# ambient
		getReal()	# translucency
		return true
	
	#---	Meta: diffuse	---#
	public def pm_diff() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		color = getColorFull()
		m.Meta['diffuse']	= Data_Color4( shader:con.slib.diffuse_u,	Value:color )
		sh = { '': null,
			'LAMBERT':	con.slib.lambert
			}[ getString() ]
		m.Meta['comp_diff']	= Advanced( shader:sh )	if sh
		return true

	#---	Meta: specular	---#
	public def pm_spec() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		color = getColorFull()
		m.Meta['specular']	= Data_Color4( shader:con.slib.specular_u,	Value:color )
		glossy = getReal()
		m.Meta['glossiness']= Data_single( shader:con.slib.glossiness_u,Value:glossy )
		sh = {
			'COOKTORR':	con.slib.cooktorr,
			'PHONG':	con.slib.phong
			}[ getString() ]
		m.Meta['comp_spec']	= Advanced( shader:sh )	if sh
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
