namespace ext.spec

import System
import System.Collections.Generic
import Boo.Lang.Compiler

#---	Make method specializations with manual modifications	---#

[AttributeUsage(AttributeTargets.Method)]
public class Method(AbstractAstAttribute):
	private final tips	= List[of Ast.SimpleTypeReference]()
	
	public def constructor(*types as (Ast.ReferenceExpression)):
		for t in types:
			st = Ast.TypeReference.Lift(t) as Ast.SimpleTypeReference
			if not st:	raise 'not a type'
			tips.Add(st)
			
	protected virtual def Mod(m as Ast.Method, t as Ast.SimpleTypeReference) as void:
		pass

	public override def Apply(node as Ast.Node) as void:
		m = node as Ast.Method
		if not m:		raise 'not a method'
		nPar = len(m.GenericParameters)
		if not nPar:	raise 'target has to be generic'
		if nPar > 1:	raise 'supports only one generic param'
		klass = m.DeclaringType
		pred = getPredicate( m.GenericParameters[0].Name )
		#printXml(m,	'method-gen')
		
		for t in tips:
			sm = m.CleanClone()
			pred = getPredicate( sm.GenericParameters[0].Name )
			sm.GenericParameters = null
			sm.ReplaceNodes(pred,t)
			klass.Members.Add(sm)
			Mod(sm,t)


#---	Make specializations with substitution, change name & cleanup	---#
[AttributeUsage(AttributeTargets.Method)]
public class ForkMethod(Method):
	protected final pred as Ast.NodePredicate
	protected final fold as Ast.ReferenceExpression
	protected final fnew as Ast.ReferenceExpression
	public final doRename	as bool

	public def constructor(ren as Ast.BoolLiteralExpression,
	old as Ast.ReferenceExpression, new as Ast.ReferenceExpression,
	*types as (Ast.ReferenceExpression)):
		super(*types)
		doRename = ren.Value
		fold,fnew = old,new
		pred = def(n as Ast.Node):
			exp = n as Ast.ReferenceExpression
			return false if not exp
			return exp.Name == fold.Name
		
	protected override def Mod(m as Ast.Method, t as Ast.SimpleTypeReference) as void:
		m.Body.Statements.Reject() do(st as Ast.Statement):
			sdec = st as Ast.DeclarationStatement
			if sdec:	# delete original declaration
				return sdec.Declaration.Name == fold.Name
			return false
		m.ReplaceNodes(pred,fnew)
		if doRename: m.Name += '_'+t.Name
