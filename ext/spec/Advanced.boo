namespace ext.spec

import System
import Boo.Lang.Compiler

internal def getPredicate(*names as (string)) as Ast.NodePredicate:
	return def(n as Ast.Node):
		st = n as Ast.SimpleTypeReference
		return false	if not st
		for n in names:
			return true	if st.Name == n
		return false
		

#---	Make method specialization with specific used class cloning & specialization	---#

[AttributeUsage(AttributeTargets.Method)]
public class MethodSubClass(Method):
	private final collector	as SpecieCollector

	public def constructor(cl as Ast.ReferenceExpression, *types as (Ast.ReferenceExpression)):
		super(*types)
		collector = SpecieCollector( cl.ToString() )
	
	private class SpecieCollector(Ast.DepthFirstVisitor):
		public final cname	as string
		public rez	as Ast.GenericReferenceExpression = null
		public def constructor(str as string):
			cname = str
		public override def OnGenericReferenceExpression(exp as Ast.GenericReferenceExpression):
			#st = Ast.TypeReference.Lift(exp.Target) as Ast.SimpleTypeReference
			st = exp.Target as Ast.ReferenceExpression
			return if not st or st.ToString() != cname
			rez = exp

	private class ParameterRazor(Ast.DepthFirstVisitor):
		public override def OnGenericTypeReference(gtr as Ast.GenericTypeReference):
			name = gtr.Name			# cut off [] part
			ind = name.IndexOf('[')
			return	if ind < 0
			gtr.Name = name.Substring(0,ind)
	
	private static index = 0
	
	protected override def Mod(m as Ast.Method, t as Ast.SimpleTypeReference) as void:
		m.Body.Accept(collector)
		clTarget = collector.rez.Target as Ast.ReferenceExpression
		return	if not collector.rez
		
		dtype = m.DeclaringType
		orig as Ast.ClassDefinition = null
		while not orig:
			assert dtype is not null
			for e in dtype.Members:
				w = e as Ast.ClassDefinition
				continue if not w or w.Name != clTarget.Name
				orig = w
			dtype = dtype.DeclaringType

		rf = Ast.ReferenceExpression( orig.Name + '_' + t.Name )
		mlist = orig.DeclaringType.Members
		cd = mlist.Item[rf.Name] as Ast.ClassDefinition
		if not cd:
			cd = orig.CleanClone()
			return	if not cd
			cd.Name = rf.Name
			gename = cd.GenericParameters[0].Name
			cd.GenericParameters = null
			fullpar = "${orig.FullName}.${gename}"
		
			pred = getPredicate(gename,fullpar)
			cd.ReplaceNodes(pred,t)
			razor = ParameterRazor()
			for b in cd.BaseTypes:
				b.Accept(razor)

			mlist.Add(cd)
			ent = TypeSystemServices.GetOptionalEntity(cd)
			TypeSystemServices.Bind(rf,ent)
	
		m.ReplaceNodes(collector.rez, rf)
		m.ReturnType.ReplaceNodes(collector.rez, rf)
		#ext.printXml(m,'method')
		#ext.printXml(cd,'class')