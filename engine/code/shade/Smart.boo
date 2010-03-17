namespace kri.shade

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#-----------------------#
#	ADVANCED SHADER 	#
#-----------------------#

public class Smart(Program):
	protected final params	= List[of rep.IBase]()
	public static final prefixAttrib	as string	= 'at_'
	public static final prefixUnit		as string	= 'unit_'
	public static final Fixed	= Smart(0)
	
	public def constructor():
		super()
	private def constructor(xid as int):
		super(xid)
	
	/* //this old method dosn't work with Uniform being in different namespace
	[ext.spec.MethodSubClass(rep.Uniform, int,single,Color4,Vector4,Quaternion)]
	public def data[of T(struct)]( *pars as (par.Basic[of T]) ) as void:
		for p in pars:
			params.Add( rep.Uniform[of T](p,getVar(p.name)) )
	*/
	
	public def unit_man(i as int, str as string) as void:
		assert not string.IsNullOrEmpty(str)
		GL.Uniform1( getVar(prefixUnit+str), i)
		p = kri.Ant.Inst.units.Par[i]
		params.Add( rep.Unit(i,p) )
	
	public def units(*indexes as (int)) as void:
		super.use()
		for i in indexes:
			unit_man(i, kri.Ant.Inst.slotUnits.Name[i])
	
	public def attribs(sl as kri.lib.Slot, *ats as (int)) as void:
		for a in ats:
			name = sl.Name[a]
			continue if string.IsNullOrEmpty(name)
			attrib(a, prefixAttrib + name)
	
	public override def use() as void:
		super()
		for p in params:
			p.upload()
	
	# link with attributes
	public def link(sl as kri.lib.Slot, *dicts as (rep.Dict)) as void:
		attribs(sl, *array[of int](range(sl.Size)))
		linkUni(*dicts)
	
	# collect used attributes
	public def gatherAttribs(sl as kri.lib.Slot) as int*:
		return (i for i in range(sl.Size)
			if not string.IsNullOrEmpty(sl.Name[i]) and
			i == GL.GetAttribLocation(id, prefixAttrib + sl.Name[i])
			)

	# link, setup units & gather uniforms
	protected def linkUni( *dicts as (rep.Dict) ) as void:
		link()
		GL.UseProgram(id)	# for texture units
		num = -1
		GL.GetProgram(id, ProgramParameter.ActiveUniforms, num)
		nar = ( GL.GetActiveUniformName(id,i) for i in range(num) )
		for name in nar:
			loc = getVar(name)
			assert loc >= 0
			if name.StartsWith('unit_'):
				tname = name.Substring(5)
				tid = kri.Ant.Inst.slotUnits.find(tname)
				assert tid >= 0
				GL.Uniform1(loc, tid)
				p = kri.Ant.Inst.units.Par[tid]
				params.Add( rep.Unit(tid,p) )
			else:
				val	as callable = null
				Array.Find(dicts) do(d):
					d.TryGetValue(name,val)
					return val != null
				#gen as callable(int) as IRepresentable = val
				assert val and 'uniform not found'
				params.Add( val(loc) )

	public def getAttribNum() as int:
		assert Ready
		num = -1
		GL.GetProgram(id, ProgramParameter.ActiveAttributes, num)
		return num

	# gather total attrib size
	public def getAttribSize() as int:
		assert Ready
		num,total,size = -1,0,0
		GL.GetProgram(id, ProgramParameter.ActiveAttributes, num)
		for i in range(num):
			tip as ActiveAttribType
			GL.GetActiveAttrib(id, i, size, tip)
			total += size
		return total
