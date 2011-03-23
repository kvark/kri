namespace kri.gen

import OpenTK
import OpenTK.Graphics.OpenGL


#---------	Frame	---------#

public class Frame:
	public final mesh	as kri.Mesh
	public final va	= kri.vb.Array()
	public def constructor(m as kri.Mesh):
		mesh = m
	public def draw(bu as kri.shade.Bundle) as bool:
		return mesh.render(va,bu,null)
	public def draw(sa as kri.shade.Mega) as bool:
		return mesh.render( va, kri.shade.Bundle(sa), null )


#---------	Wrap	---------#

public class Mesh( kri.Mesh ):
	public def constructor(mode as BeginMode):
		super(mode)
	public def constructor(mode as BeginMode, con as Constructor):
		super(mode)
		con.apply(self)
	public def wrap(mat as kri.Material) as kri.Entity:
		ent = kri.Entity(mesh:self)
		tm = kri.TagMat( num:nPoly, mat:mat )
		ent.tags.Add(tm)
		return ent


#---------	POINT	---------#

public class Point( Mesh ):
	public def constructor():
		super( BeginMode.Points )
		.nVert = .nPoly = 1
		vat = kri.vb.Attrib()
		vat.init(1)
		ai = kri.vb.Info( name:'vertex', size:1,
			type:VertexAttribPointerType.UnsignedByte )
		vat.Semant.Add(ai)
		vbo.Add(vat)


#---------	QUAD	---------#

public class Quad( Mesh ):
	public def constructor():
		super( BeginMode.TriangleStrip )
		self.nVert = 4
		self.nPoly = 4
		vat = kri.vb.Attrib()
		vat.init[of Vector2h]((of Vector2h:
			Vector2h(-1f,-1f),	Vector2h(1f,-1f),
			Vector2h(-1f,1f),	Vector2h(1f,1f),
			), false)
		ai = kri.vb.Info( name:'vertex', size:2,
			type:VertexAttribPointerType.HalfFloat )
		vat.Semant.Add(ai)
		vbo.Add(vat)


#----	LINE OBJECT (-1,1)	----#

public class Line( Mesh ):
	public def constructor():
		super( BeginMode.Lines )
		self.nVert = 2
		self.nPoly = 1
		data = (of Vector4: Vector4(-1f,0f,0f,1f), Vector4(1f,0f,0f,1f))
		vat = kri.vb.Attrib()
		vat.init( data, false )
		kri.Help.enrich(vat, 4, 'vertex')
		vbo.Add(vat)



#----	PLANE OBJECT	----#
# param: half-size of sides

public class Plane( Mesh ):
	public def constructor(scale as Vector2):
		con = Constructor( v:array[of Vertex](4) )
		sar = (-1f,1f)
		for i in range(4):
			con.v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
			con.v[i].rot = Quaternion.Identity
		super( BeginMode.TriangleStrip, con )

public class PlaneTex( Mesh ):
	public def constructor(scale as Vector2):
		v = array[of VertexUV](4)
		sar,str = (-1f,1f),(0f,1f)
		for i in range(4):
			v[i].uv = Vector2( str[i&1], str[i>>1] )
			v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
			v[i].rot = Quaternion.Identity
		# create mesh
		super( BeginMode.TriangleStrip )
		self.nVert = 4
		self.nPoly = 4
		# fill vbo
		vat = kri.vb.Attrib()
		vat.init( v, false )
		# fill semantics
		kri.Help.enrich(vat, 4, 'vertex','quat')
		kri.Help.enrich(vat, 2, 'tex0')
		# return
		vbo.Add(vat)
