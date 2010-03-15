namespace ext

import System
import System.Collections.Generic
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast


#---	Original method specializator by Cedric Vivier	---#

[AttributeUsage(AttributeTargets.Method)]
public class AutoSpecializeAttribute(AbstractAstAttribute):
	m as Method

	public override def Apply(node as Node) as void:
		m = node as Method
		if not m:		raise "must be applied to a method"
		nPar = len(m.GenericParameters)
		if not nPar:	raise "method has to be generic"
		if nPar > 1:	raise "supports only one generic param"

		klass = m.DeclaringType
		gpr = FindGenericParameter()
		candidates = SpecializableCollector(m, gpr.Name).Results
		if not len(candidates):	raise "no  candidate for specialization"
		if len(candidates) > 1:	raise "too many candidates for specialization"

		specializations = List[of Method]()
		for result in candidates:
			for member in klass.Members:
				continue	if member.NodeType != NodeType.Method or member.Name != result.Name
				candidate = cast(Method, member)
				continue	if len(candidate.GenericParameters)
				specializations.Add( CreateSpecialization(candidate, gpr, result) )
		for sm in specializations:
			klass.Members.Add(sm)
		#klass.Members.Extend( specializations )

	private def FindGenericParameter():
		i = 0
		for p in m.Parameters:
			str = p.Type as SimpleTypeReference
			continue if not str
			if str.Name == m.GenericParameters[0].Name:
				return Result(Name: p.Name, Offset: i)
			++i
		return Result()

	private def CreateSpecialization(candidate as Method, srcArg as Result, dstArg as Result):
		#sm = cast(Method, m.Clone())
		sm as Method	= m.Clone()
		sm.GenericParameters = null
		tOrig = candidate.Parameters[dstArg.Offset].Type
		sm.Parameters[srcArg.Offset].Type = tOrig.Clone() as TypeReference
		return sm


	private struct Result:
		public Name as string
		public Offset as int

	private class SpecializableCollector(DepthFirstVisitor):
	"""
	Captures in `Results' all names of non-generic method invocation using parameter `name'.
	"""
		method as Method
		name as string
		[getter(Results)]
		results = List[of Result]()

		internal def constructor(method as Method, name as string):
			return if not name
			.name = name
			.method = method
			method.Body.Accept(self)

		public override def OnReferenceExpression(node as ReferenceExpression):
			return if node.Name != name
			mie = node.ParentNode as MethodInvocationExpression
			if mie and mie.Target isa ReferenceExpression: #not GenericRef
				res = Result(
					Name: cast(ReferenceExpression, mie.Target).Name,
					Offset: mie.Arguments.IndexOf(node) )
				results.Add(res) unless results.Contains(res)
