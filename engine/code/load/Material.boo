namespace kri.load

import kri.meta
import OpenTK.Graphics

public partial class Native:
	public final limdic		= Dictionary[of string,callable() as Hermit]()
	public static final defMapin = Hermit()

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

	
	#---	Map input	---#
	public def p_mapin() as bool:
		name = getString(SHORT_LEN)
		fun as callable() as Hermit = null
		if limdic.TryGetValue(name,fun):
			mt = fun()
		else: mt = defMapin
		puData(mt)
		return mt != defMapin


	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return Targa(str).Result.generate()

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
		id = br.ReadByte()
		assert id < 1
		mDiff.shader = con.slib.lambert
		id = br.ReadByte()
		assert id < 2
		mSpec.shader = (con.slib.cooktorr, con.slib.phong)[id]
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


	#---	Enumerations	---#
	#! have to be the same as the export script uses
	public enum TexType:
		None
		Diffuse
		Normal
		Emission
		Specular
		Reflection
	
	private struct UniData:
		public id	as int
		public sh	as kri.shade.Object		
	
	#---	Parse texture slot	---#
	public def p_tex() as bool:
		m	= geData[of kri.Material]()
		inp	= geData[of Hermit]()
		return false	if not m
		tip		= cast(TexType,		br.ReadByte())
		return true		if tip == TexType.None
		Image.bRepeat	= br.ReadByte()>0	# extend by repeat
		Image.bMipMap	= br.ReadByte()>0	# generate mip-maps
		Image.bFilter	= br.ReadByte()>0	# linear filtering
		# create unit with proper shaders
		us = kri.Ant.inst.units
		uniDict = Dictionary[of TexType,UniData]()
		uniDict[TexType.Diffuse		] = UniData( id:us.texture,	sh:con.slib.text_2d )
		uniDict[TexType.Normal		] = UniData( id:us.bump,	sh:con.slib.bump_2d )
		uniDict[TexType.Reflection	] = UniData( id:us.reflect,	sh:con.slib.refl_2d )
		udata as UniData
		if not uniDict.TryGetValue(tip,udata):
			return false
		sh_gen = con.slib.getCoordGen( inp.Name, udata.id ) 
		m.unit[ udata.id ] = un = Unit( inp, sh_gen, udata.sh )
		# texcoords & image path
		un.Offset	= Vector4(getVector(), 0.0)
		un.Scale	= Vector4(getVector(), 1.0)
		un.tex = getTexture( 'res' + getString(PATH_LEN) )
		return true
