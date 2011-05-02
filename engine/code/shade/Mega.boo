namespace kri.shade

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


public struct Uniform:
	public name	as string
	public size	as int
	public type	as ActiveUniformType

	public def genParam(loc as int, iv as par.IBaseRoot, ref tun as int) as Parameter:
		if size!=1 or not iv:
			return null
		it = iv.GetType().GetInterface('IBase`1')
		T = object
		if it:	T = it.GetGenericArguments()[0]
		if T == kri.buf.Texture and name.StartsWith( Mega.PrefixUnit ):
			tn = tun++
			return ParTexture(loc,iv,tn)
		elif T == int				and type in (ActiveUniformType.Int,ActiveUniformType.UnsignedInt):
			return ParUni_int(loc,iv)
		elif T == bool				and type == ActiveUniformType.Bool:
			return ParUni_bool(loc,iv)
		elif T == single			and type == ActiveUniformType.Float:
			return ParUni_single(loc,iv)
		elif T == Vector4			and type == ActiveUniformType.FloatVec4:
			return ParUni_Vector4(loc,iv)
		elif T == Quaternion		and type == ActiveUniformType.FloatVec4:
			return ParUni_Quaternion(loc,iv)
		elif T == Graphics.Color4	and type == ActiveUniformType.FloatVec4:
			return ParUni_Color4(loc,iv)
		kri.lib.Journal.Log("Uniform: '${name} doesn't match: ${type} for ${iv.GetType()}")
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
	public	final attribs	= array[of Attrib]( kri.Ant.Inst.caps.vertexAttribs )
	public	final uniforms	= List[of Uniform]()
	public	final static PrefixAttrib	as string	= 'at_'
	public	final static PrefixUnit		as string	= 'unit_'
	
	public override def link() as bool:
		if not super():
			return false
		# read attribs
		num = size = -1
		GL.GetProgram( handle, ProgramParameter.ActiveAttributes, num )
		for i in range(num):
			at = Attrib()
			str = GL.GetActiveAttrib( handle, i, size, at.type )
			assert str.StartsWith( PrefixAttrib )
			at.name = str.Substring( PrefixAttrib.Length )
			at.size = size
			loc = GL.GetAttribLocation( handle, str )
			attribs[loc] = at
		# read uniforms
		uniforms.Clear()
		GL.GetProgram( handle, ProgramParameter.ActiveUniforms, num )
		for i in range(num):
			uni = Uniform()
			uni.name = GL.GetActiveUniform( handle, i, uni.size, uni.type )
			uniforms.Add(uni)
		return true
	
	public override def clear() as void:
		super()
		for i in range(attribs.Length):
			attribs[i].name = ''
		uniforms.Clear()
