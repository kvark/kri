namespace kri.load

import kri.meta
import OpenTK.Graphics

public partial class Native:
	public final limdic		= Dictionary[of string,callable() as Hermit]()

	public def fillMapinDict() as void:
		sob = Dictionary[of string, kri.shade.Object]()
		def genFun(x as Hermit):
			return {return x}
		for s in ('GLOBAL','OBJECT','UV','ORCO','WINDOW','NORMAL','REFLECTION','TANGENT'):
			slow = s.ToLower()
			sob[s] = sh = kri.shade.Object( "/mi/${slow}_v" )
			mt = Hermit( shader:sh, Name:slow )	# careful!
			limdic[s] = genFun(mt)
		limdic['OBJECT'] = do():
			name = getString(STR_LEN)
			mio = InputObject( shader:sob['OBJECT'], Name:'object' )
			finalActions.Add() do():
				nd = at.nodes[name]
				mio.pNode.activate(nd)
			return mio
		limdic['ORCO'] = do():
			getString(NAME_LEN)	# mapping type, not supported
			return Hermit( shader:sob['ORCO'], Name:'orco' )


	#---	Parse texture unit	---#
	public def pm_unit() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		u = AdUnit()
		puData(u)
		targets = { 'colordiff':'diffuse' }
		# map targets
		for i in range( br.ReadByte() ):
			name = getString(STR_LEN)
			targ = targets[name]
			continue	if not targ
			u.Name = targ	if System.String.IsNullOrEmpty(u.Name)
			m.Meta[targ].unit = u
		# map inputs
		name = getString(SHORT_LEN)
		fun as callable() as Hermit = null
		if limdic.TryGetValue(name,fun):
			u.input = fun()
			return true
		return false


	#---	Parse material	---#
	public def p_mat() as bool:
		m = kri.Material( getString(STR_LEN) )
		at.mats[m.name] = m
		puData(m)
		scalars = kri.shade.par.Value[of Vector4]()
		m.meta[ con.ms.emissive ] = mEmis = Emission()
		m.meta[ con.ms.diffuse	] = mDiff = Diffuse(scalars)
		m.meta[ con.ms.specular	] = mSpec = Specular(scalars)
		m.meta[ con.ms.parallax	] = mParx = Parallax(scalars)
		# colors
		mEmis.Color = getColorByte()
		mDiff.Color = getColorByte()
		mSpec.Color = getColorByte()
		# models
		str = getString(SHORT_LEN)
		assert str == 'LAMBERT'
		mDiff.shader = con.slib.lambert
		str = getString(SHORT_LEN)
		assert str in ('COOKTORR','PHONG')
		mSpec.shader = con.slib.phong
		# params
		mDiff.Reflection	= getReal()
		mSpec.Specularity	= getReal()
		mSpec.Glossiness	= getReal()
		mParx.Shift			= getReal()
		mParx.shader = (con.slib.shift0, con.slib.shift1)[ mParx.Shift != 0.0 ]
		# META2 style
		m.Meta['emissive']	= Data_Color4( shader:con.slib.emissive_u,	Value:mEmis.Color )
		m.Meta['diffuse']	= Data_Color4( shader:con.slib.diffuse_u,	Value:mDiff.Color )
		m.Meta['specular']	= Data_Color4( shader:con.slib.specular_u,	Value:mSpec.Color )
		m.Meta['glossiness']	= Data_single( shader:con.slib.glossiness_u,	Value:mSpec.Glossiness )
		m.Meta['bump']		= Data_Color4( shader:con.slib.bump_c )
		# units
		con.mDef.unit.CopyTo( m.unit,0 )
		return true


	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return null	if not str.EndsWith('.tga')
		return image.Targa(str).Result.generate()
	
	private struct UniData:
		public id	as int
		public sh	as kri.shade.Object		
	
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
		u.Value = getTexture( 'res' + getString(PATH_LEN) )
		return u.Value != null
