namespace kri.shade

import System.IO
import System.Collections.Generic
import OpenTK.Graphics.OpenGL

//----------------------------------//
//		BASIC OBJECT LOADER			//
//----------------------------------//

public class Loader( kri.res.ILoaderGen[of Object] ):
	public def read(path as string) as Object:
		text = Code.Read(path)
		type = Object.Type(path)
		return Object(type, path, text)


//------------------------------------------//
//		CODE INTERFACE & IMPLEMENTATION		//
//------------------------------------------//

public interface ICode:
	Text	as string:
		get
	def getMethod(base as string) as string

public class CodeNull(ICode):
	ICode.Text as string:
		get: return null
	def ICode.getMethod(base as string) as string:
		return null


public class Code(ICode):
	public static Folder	= '.'
	public static def Read(name as string) as string:
		if name.StartsWith('/'):
			name = Folder + name
		name += '.glsl'
		kri.res.Manager.Check(name)
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
	public Null as bool:
		get: return string.IsNullOrEmpty(val) or string.IsNullOrEmpty(oper)
	public static final Void	= DefMethod( type:'void' )
	public static final Float	= DefMethod( type:'float', val:'1.0', oper:'*' )


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
		if dm.Null:
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
	
	public def compose( sem as kri.vb.Info*, sl as kri.lib.Slot, *dicts as (rep.Dict) ) as void:
		assert root
		prog.add('/lib/quat_v')
		prog.add(root)
		prog.add( *extra.ToArray() )
		if sem:
			names = array( 'to_'+sl.Name[at.slot] for at in sem )
			prog.feedback(false,*names)
		prog.link(sl,*dicts)


//------------------------------//
//		TEMPLATE CLASS			//
//------------------------------//

public class Template(ICode):
	private final dict	= Dictionary[of string,Object]()
	[Getter(Text)]
	private final text		as string
	private final keys		as (string)
	public final tip		as ShaderType
	
	public def constructor(path as string):
		text = Code.Read(path)
		tip = Object.Type(path)
		dk = Dictionary[of string,object]()
		pos = 0
		while (p2 = text.IndexOf('%',pos)) >=0:
			pos = p2+1
			dk[ text.Substring(pos,1).ToLower() ] = null
		keys = array( dk.Keys )

	def ICode.getMethod(base as string) as string:
		return null
	
	public def instance(d as Dictionary[of string,IDictionary[of string,string]]) as Object:
		key = join( join("${v.Key}-${v.Value}" for v in d[k],',') for k in keys, ':')
		sh as Object = null
		if dict.TryGetValue(key,sh):
			return sh
		rez = ''
		def append(line as string):
			pos = line.IndexOf('%')
			if pos>=0:
				k = line.Substring(pos+1,1).ToLower()
				assert d.ContainsKey(k)
				for sub in d[k]:
					append( line.Replace('%'+k,sub.Key).Replace('%'+k.ToUpper(),sub.Value) )
			else: rez += line + "\n"
		for line in text.Split( "\n".ToCharArray()[0] ):
			append(line)
		dict[key] = sh = Object(tip,'template',rez)
		return sh
