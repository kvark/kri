namespace kri.load

import OpenTK.Graphics

public partial class Native:
	protected def getColor() as Color4:
		c = br.ReadBytes(4)	#rbga
		return Color4(c[0],c[2],c[1],c[3])
	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return Targa(str).Result.generate()

	#---	Parse material	---#
	public def p_mat() as bool:
		m = kri.Material( getString(STR_LEN) )
		at.mats[m.name] = m
		puData(m)
		m.meta[ con.ms.emissive ] = mEmis = kri.meta.Emission	( con.ms.pEmissive )
		m.meta[ con.ms.diffuse	] = mDiff = kri.meta.Diffuse	( con.ms.pDiffuse,	con.ms.pMatData )
		m.meta[ con.ms.specular	] = mSpec = kri.meta.Specular	( con.ms.pSpecular,	con.ms.pMatData )
		m.meta[ con.ms.parallax	] = mParx = kri.meta.Parallax	( con.ms.pMatData )
		# colors
		mEmis.color = getColor()
		mDiff.color = getColor()
		mSpec.color = getColor()
		# models
		id = br.ReadByte()
		assert id < 1
		mDiff.shader = con.slib.lambert
		id = br.ReadByte()
		assert id < 2
		mSpec.shader = (con.slib.cooktorr, con.slib.phong)[id]
		# params
		mDiff.kReflection	= getReal()
		mSpec.kSpecularity	= getReal()
		mSpec.kGlossiness	= getReal()
		mParx.kShift		= getReal()
		mParx.shader = (con.slib.shift0, con.slib.shift1)[ mParx.kShift != 0.0 ]
		# units
		con.mDef.unit.CopyTo( m.unit,0 )
		return true
	
	#---	Enumerations	---#
	#have to be the same as the export script uses
	public enum TexType:
		None
		Diffuse
		Normal
		Emission
		Specular
		Reflection
	public enum TexCoord:
		Tangent
		Reflection
		Normal
		Window
		UV
		Object
		Global
	public enum TexMapping:
		Sphere
		Tube
		Cube
		Flat
		
	#---	Parse texture slot	---#
	public def p_tex() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		tip		= cast(TexType,		br.ReadByte())
		return true		if tip == TexType.None
		coord	= cast(TexCoord,	br.ReadByte())
		mapping = cast(TexMapping,	br.ReadByte())
		Image.bRepeat	= br.ReadByte()>0	# extend by repeat
		Image.bMipMap	= br.ReadByte()>0	# generate mip-maps
		Image.bFilter	= br.ReadByte()>0	# linear filtering
		return false	if mapping != TexMapping.Flat
		tex = getTexture( 'res' + getString(PATH_LEN) )
		if   tip == TexType.Diffuse:
			assert coord == TexCoord.UV
			m.unit[kri.Ant.inst.units.texture	] = kri.meta.Unit(
				tex, con.slib.text_gen1, con.slib.text_2d )
		elif tip == TexType.Normal:
			assert coord == TexCoord.UV
			m.unit[kri.Ant.inst.units.bump		] = kri.meta.Unit(
				tex, con.slib.bump_gen1, con.slib.bump_2d )
		elif tip == TexType.Reflection:
			assert coord == TexCoord.Reflection
			m.unit[kri.Ant.inst.units.reflect	] = kri.meta.Unit(
				tex, con.slib.refl_gen, con.slib.refl_2d )
		else:	return false
		return true
