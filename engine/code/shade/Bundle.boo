namespace kri.shade

import System.Collections.Generic
import OpenTK


public class Parameter:
	public abstract def upload() as void:
		pass

# Uniform param representor
[ext.spec.Class(( int, single, Vector4, Quaternion, Graphics.Color4 ))]
[ext.RemoveSource]
public class ParUni[of T(struct)](Parameter):
	public final loc	as int
	public final piv	as par.IBase[of T]
	public def constructor(lc as int, iv as par.IBase[of T]):
		assert iv
		loc = lc
		piv = iv
	public override def upload() as void:
		data = piv.Value
		Program.Param(loc,data)


public class ParTexture(Parameter):
	public final loc	as int
	public final piv	as par.IBase[of kri.buf.Texture]
	public final tun	as int
	public def constructor(lc as int, iv as par.IBase[of kri.buf.Texture], tn as int):
		assert iv and tn>=0
		loc,tun = lc,tn
		piv = iv
	public override def upload() as void:
		slot = tun
		kri.buf.Texture.Slot(slot)
		Program.Param(loc,slot)
		piv.Value.bind()



#---------

public class Bundle:
	public	final shader	as Mega
	public	final dicts		= List[of par.Dict]((kri.Ant.Inst.dict,))
	private	final params	= List[of Parameter]()
	
	public	final static Empty	= Bundle(null as Mega)
	
	public def constructor():
		shader = Mega()
	public def constructor(sh as Mega):
		shader = sh
	public def constructor(bu as Bundle):
		shader = bu.shader
	
	public def fillParams() as void:
		assert shader.Ready
		params.Clear()
		tun = 0
		for uni in shader.uniforms:
			iv	as par.IBaseRoot = null
			for d in dicts:
				d.TryGetValue( uni.name, iv )
				if iv: break
			assert iv
			loc = shader.getLocation( uni.name )
			p = uni.genParam(loc,iv,tun)
			assert p
			params.Add(p)

	public def link() as void:
		shader.link()
		fillParams()

	public def activate() as void:
		if not shader.Ready:
			link()
		shader.bind()
		for p in params:
			p.upload()
	
	public def clear() as void:
		shader.clear()
		dicts.Clear()
		params.Clear()

	public def pushAttribs(ind as kri.vb.Object, va as kri.vb.Array, dict as Dictionary[of string,kri.vb.Entry]) as bool:
		if not shader.Ready:
			link()
		return va.pushAll( ind, shader.attribs, dict )
