namespace Boo.Lang.Extensions

import Boo.Lang.Compiler
import Boo.Lang.PatternMatching

#---	Transparent property portal		---#

macro portal(bex as Ast.BinaryExpression):
	assert bex and bex.Operator == Ast.BinaryOperatorType.Assign
	# the type inference doesn't work perfectly with macroses
	# so I need to pass the type explicitely here
	lef = bex.Left	as Ast.TryCastExpression
	rit = bex.Right as Ast.ReferenceExpression
	assert lef and 'The type is missing'
	name = lef.Target	as Ast.ReferenceExpression
	type = lef.Type		as Ast.TypeReference
	yield [|
		public $(name) as $(type):
			get: return $(rit)
			set: $(rit) = value
	|]
