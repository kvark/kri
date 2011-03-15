namespace kri.shade

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


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


public struct Uniform:
	public name	as string
	public size	as int
	public type	as ActiveUniformType

	public def genParam(loc as int, iv as par.IBaseRoot, ref tun as int) as Parameter:
		return null	if not iv
		assert size == 1
		it = iv.GetType().GetInterface('IBase`1')
		assert it
		T = it.GetGenericArguments()[0]
		if T == int:
			assert type in (ActiveUniformType.Int,ActiveUniformType.UnsignedInt)
			return ParUni_int(loc,iv)
		elif T == single:
			assert type == ActiveUniformType.Float
			return ParUni_single(loc,iv)
		elif T == Vector4:
			assert type == ActiveUniformType.FloatVec4
			return ParUni_Vector4(loc,iv)
		elif T == Quaternion:
			assert type == ActiveUniformType.FloatVec4
			return ParUni_Quaternion(loc,iv)
		elif T == Graphics.Color4:
			assert type == ActiveUniformType.FloatVec4
			return ParUni_Color4(loc,iv)
		elif T == kri.buf.Texture:
			assert name.StartsWith( Mega.PrefixUnit )
			tn = tun++
			return ParTexture(loc,iv,tn)
		return null



public struct Attrib:
	public name as string
	public type as ActiveAttribType
	public size	as byte

	public def matches(ref at as kri.vb.Info) as bool:
		nc = -1	# number of components
		if at.integer:
			if not at.type in (
				VertexAttribPointerType.Byte,	VertexAttribPointerType.UnsignedByte,
				VertexAttribPointerType.Short,	VertexAttribPointerType.UnsignedShort,
				VertexAttribPointerType.Int,	VertexAttribPointerType.UnsignedInt):
				return false
			nc=1	if type in (ActiveAttribType.Int	,ActiveAttribType.UnsignedInt)
			nc=2	if type in (ActiveAttribType.IntVec2,ActiveAttribType.UnsignedIntVec2)
			nc=3	if type in (ActiveAttribType.IntVec3,ActiveAttribType.UnsignedIntVec3)
			nc=4	if type in (ActiveAttribType.IntVec4,ActiveAttribType.UnsignedIntVec4)
		else:
			nc=1	if type in (ActiveAttribType.Float		,ActiveAttribType.Double)
			nc=2	if type in (ActiveAttribType.FloatVec2	,ActiveAttribType.DoubleVec2)
			nc=3	if type in (ActiveAttribType.FloatVec3	,ActiveAttribType.DoubleVec3)
			nc=4	if type in (ActiveAttribType.FloatVec4	,ActiveAttribType.DoubleVec4)
			nc=4	if type in (ActiveAttribType.FloatMat2	,ActiveAttribType.DoubleMat2)
			nc=9	if type in (ActiveAttribType.FloatMat3	,ActiveAttribType.DoubleMat3)
			nc=16	if type in (ActiveAttribType.FloatMat4	,ActiveAttribType.DoubleMat4)
		return nc*size == at.size


#---------

public class Mega(Program):
	private attribs	as (Attrib) = null
	private final uniforms	= List[of Uniform]()
	public static final PrefixAttrib	as string	= 'at_'
	public static final PrefixGhost		as string	= 'ghost_'
	public static final GhostSym		as string	= '@'
	public static final PrefixUnit		as string	= 'unit_'
	
	public Attributes as (Attrib):
		get: return attribs
	public Uniforms as Uniform*:
		get: return uniforms
	
	public override def link() as void:
		super()
		assert Ready
		# read attribs
		num = size = -1
		GL.GetProgram( handle, ProgramParameter.ActiveAttributes, num )
		attribs = array[of Attrib](num)
		for i in range(num):
			str = GL.GetActiveAttrib( handle, i, size, attribs[i].type )
			assert str.StartsWith( PrefixAttrib )
			attribs[i].name = str.Substring( PrefixAttrib.Length )
			attribs[i].size = size
		# read uniforms
		uniforms.Clear()
		GL.GetProgram( handle, ProgramParameter.ActiveUniforms, num )
		for i in range(num):
			uni = Uniform()
			uni.name = GL.GetActiveUniform( handle, i, uni.size, uni.type )
			uniforms.Add(uni)
	
	public override def clear() as void:
		super()
		attribs = null
		uniforms.Clear()


#---------

public class Bundle:
	public	final shader	as Mega
	public	final dicts		= List[of rep.Dict]((kri.Ant.Inst.dict,))
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
		for uni in shader.Uniforms:
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
		shader.bind()
		for p in params:
			p.upload()
	
	public def clear() as void:
		shader.clear()
		dicts.Clear()
		params.Clear()
	
	public static def PushAttribs(sat as (Attrib), vat as kri.vb.Attrib*) as int:
		names = List[of string]()
		for cur in sat:
			assert cur.name and cur.size
			if cur.name in names:
				continue
			target as kri.vb.Info
			for at in vat:
				off = total = 0
				for sem in at.Semant:
					if sem.name == cur.name:
						target = sem
						off = total
					total += sem.fullSize()
				if target.size:
					at.bind()
					break
			if not cur.matches(target):
				return -1
			target.slot = names.Count
			names.Add( cur.name )
			kri.vb.Attrib.Push(target,off,total)
		return names.Count

	public def pushAttribs(combined as kri.vb.Attrib*) as int:
		assert shader.Ready
		return PushAttribs( shader.Attributes, combined )
