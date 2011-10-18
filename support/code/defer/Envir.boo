namespace support.defer.env

import OpenTK


public class Meta( kri.meta.Data[of Vector4] ):
	public def constructor():
		super( 'envir', null, Vector4.Zero )


public class Extra( kri.IExtension ):
	private final fi	= kri.buf.Holder()
	private final fo	= kri.buf.Holder()
	
	public def pt_cube(r as kri.load.Reader) as bool:
		m = r.geData[of kri.Material]()
		u = r.geData[of kri.meta.AdUnit]()
		if not (m and u) :	return false
		# add 2d->cube conversion to the post loading
		r.addPostProcess() do(n as kri.Node):
			fi.at.color[0] = u.Value
			tr = kri.gen.Texture.toCube((fi,fo))
			if not tr:
				kri.lib.Journal.Log("Envir: error converting to cube: ${u.Value.Description}")
			else: u.Value = tr
		# add meta
		meta = Meta()
		meta.Unit = m.unit.IndexOf(u)
		m.metaList.Add(meta)
		return true
		
	def kri.IExtension.attach(nt as kri.load.Native) as void:
		nt.readers['t_cube'] = pt_cube



public class Apply( kri.rend.Basic ):
	public	final	bu		= kri.shade.Bundle()
	private	final	pTex	= kri.shade.par.Texture('env')
	private	final	pMulti	= kri.shade.par.Value[of Vector4]('env_multi')
	private	final	va		= kri.vb.Array()
	private	mesh	as kri.Mesh		= null
	private dict	as kri.vb.Dict	= null
	
	public def constructor(con as support.defer.Context):
		bu.shader.add('/zcull_v','/lib/quat_v','/lib/tool_v')
		bu.shader.add('/g/env_f','/lib/math_f','/lib/defer_f')
		d = kri.shade.par.Dict()
		d.unit(pTex)
		d.var(pMulti)
		bu.dicts.AddRange(( d, con.dict ))
		bu.link()
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate( link.Target.Same, 0f, false )
		scene = kri.Scene.Current
		if not scene:	return
		using blend = kri.Blender():
			blend.add()
			for e in scene.entities:
				for tm in e.enuTags[of kri.TagMat]():
					meta = tm.mat.Meta['envir'] as Meta
					if not (meta and meta.Unit>=0):	continue
					pMulti.Value = meta.Value
					pTex.Value = tm.mat.unit[meta.Unit].Value
					dict = e.CombinedAttribs
					e.mesh.render( va,bu, dict, tm.off, tm.num, 1,null )
