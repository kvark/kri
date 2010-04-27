namespace kri.shade

import System.IO
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


//------------------------------------------//
//		CODE INTERFACE & IMPLEMENTATION		//
//------------------------------------------//

public interface ICode:
	Text	as string:
		get
	def getMethod(base as string) as string


public class Code(ICode):
	public static Folder	= '../engine/shader'
	public static def Read(name as string) as string:
		if name.StartsWith('/'):
			name = Folder + name
		name += '.glsl'
		kri.res.check(name)
		return File.OpenText(name).ReadToEnd()

	[Getter(Text)]
	private final text	as string
	
	public def constructor(path as string):
		text = Read(path)
	public def constructor(cd as ICode):
		text = cd.Text
	
	def ICode.getMethod(base as string) as string:
		return null	if string.IsNullOrEmpty(text)
		pos = text.IndexOf(base)
		return null	if pos<0
		p2 = text.IndexOf('()',pos)
		assert p2>=0
		return text.Substring(pos,p2+2-pos)
	

//------------------------------//
//		COLLECTOR CLASS			//
//------------------------------//
#todo: use factory for linking

public struct DefMethod:
	public type as string
	public val	as string
	public oper	as string
	public Void as bool:
		get: return string.IsNullOrEmpty(val) or string.IsNullOrEmpty(oper)
	

public class Collector:
	public final prog	= Smart()
	public final mets	= Dictionary[of string,DefMethod]()
	public root			as Object	= null
	public extra		= List[of Object]()
	
	public def gather(method as string, codes as List[of ICode]) as Object:
		dm = mets[method]
		names = List[of string]()
		for cd in codes:
			cur = cd.getMethod(method+'_')
			assert not cur in names
			names.Add(cur)	if cur != null
		# gather to the new code
		decl = join("\n${dm.type} ${n};"	for n in names)
		if dm.Void:
			body = join("\n\t${n};"			for n in names)
		else:
			help = join("\n\tr${dm.oper}= ${n};"	for n in names)
			body = "\n\t${dm.type} r= ${dm.val};${help}\n\treturn r;"
		all = "#version 130\n${decl}\n\n${dm.type} ${method}()\t{${body}\n}"
		return Object( ShaderType.VertexShader, 'met_'+method, all)
	
	public def absorb[of T( ICode, kri.meta.IShaded )](codes as List[of T]) as void:
		# todo: use IEnumerable istead of List
		# currently produces ivalid IL code
		cl = List[of ICode]()
		for cd in codes:
			cl.Add(cd as ICode)
			prog.add( cd.Shader )
		for key in mets.Keys:
			sh = gather( key, cl )
			prog.add(sh)
	
	public def compose( sem as kri.vb.attr.Info*, sl as kri.lib.Slot, *dicts as (rep.Dict) ) as void:
		assert root
		prog.add('quat')
		prog.add(root)
		prog.add( *extra.ToArray() )
		if sem:
			names = array( 'to_'+sl.Name[at.slot] for at in sem )
			kri.TransFeedback.Setup(prog, false, *names)
		prog.link(sl,*dicts)
