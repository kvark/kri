namespace kri.load

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL
import kri.shade


#------		LOAD CONTEXT		------#

public class Meta:
	# params
	public final pEmissive	= par.Value[of Color4]()
	public final pDiffuse	= par.Value[of Color4]()
	public final pSpecular	= par.Value[of Color4]()
	public final pMatData	= par.Value[of Vector4]()
	# metas
	public final emissive	as int
	public final diffuse	as int
	public final specular	as int
	public final parallax	as int
	public final reflection	as int
	# create
	public def constructor(sm as kri.lib.Slot, d as rep.Dict):
		emissive	= sm.getForced('emissive')
		diffuse		= sm.getForced('diffuse')
		specular	= sm.getForced('specular')
		parallax	= sm.getForced('parallax')
		reflection	= sm.getForced('reflection')
		d.add('mat.emissive',	pEmissive)
		d.add('mat.diffuse',	pDiffuse)
		d.add('mat.specular',	pSpecular)
		d.add('mat_scalars',	pMatData)
		

public class Shade:
	# light models
	public final lambert	= Object('/mod/lambert_f')
	public final cooktorr	= Object('/mod/cooktorr_f')
	public final phong		= Object('/mod/phong_f')
	# parallax
	public final shift0		= Object('/mod/shift0_f')
	public final shift1		= Object('/mod/shift1_f')
	# meta units
	public final text_gen0	= Object('/mod/text_0_v')
	public final text_gen1	= Object('/mod/text_uv_v')
	public final text_2d	= Object('/mod/text_2d_f')
	public final bump_gen0	= Object('/mod/bump_0_v')
	public final bump_gen1	= Object('/mod/bump_uv_v')
	public final bump_2d	= Object('/mod/bump_2d_f')
	public final refl_gen	= Object('/mod/refl_v')
	public final refl_2d	= Object('/mod/refl_2d_f')
	
	#---	TexCoord shader storage	---#
	public final coordMap	= Dictionary[of string,Object]()
	public def getCoordGen(input as string, uid as int) as Object:
		uname = kri.Ant.Inst.slotUnits.Name[uid]
		skey = "${input}:${uname}"
		rez as Object = null
		if coordMap.TryGetValue(skey,rez):
			return rez
		text = """ ${kri.Ant.Inst.shaders.header}
			uniform vec4 offset_${uname}, scale_${uname};
			vec3 mi_${input}();	vec4 tc_${uname}()	{
				vec4 v = vec4( mi_${input}(), 0.0 );
				return offset_${uname} + v * scale_${uname};
			}"""
		coordMap[skey] =rez= Object( ShaderType.VertexShader, text )
		return rez


public class Context:
	public final ms		= Meta(kri.Ant.Inst.slotMetas, kri.Ant.Inst.dict)
	public final slib	= Shade()
	public final mDef	= kri.Material('default')
	
	public static def MakeTex(*data as (byte)) as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.bind()
		kri.Texture.Filter(false,false)
		kri.Texture.Init(1,1, PixelInternalFormat.Rgba8, data)
		return tex
	
	public def constructor():
		scalars = par.Value[of Vector4]()
		mDef.meta[ ms.emissive	]	= kri.meta.Emission()
		mDef.meta[ ms.diffuse	]	= mDiff = kri.meta.Diffuse(scalars)
		mDef.meta[ ms.specular	]	= mSpec = kri.meta.Specular(scalars)
		mDef.meta[ ms.parallax	]	= mParx = kri.meta.Parallax(scalars)
		mDiff.shader = slib.lambert
		mSpec.shader = slib.phong
		mParx.shader = slib.shift0
		un as kri.meta.Unit = null
		mDef.unit[ kri.Ant.Inst.units.texture	] =un= kri.meta.Unit( null, slib.text_gen0, slib.text_2d )
		un.tex = MakeTex(0xFF,0xFF,0xFF,0xFF)
		mDef.unit[ kri.Ant.Inst.units.bump		] =un= kri.meta.Unit( null, slib.bump_gen0, slib.bump_2d )
		un.tex = MakeTex(0x80,0x80,0xFF,0x80)
