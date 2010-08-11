namespace kri.gen

import OpenTK
import OpenTK.Graphics.OpenGL


public class Frame:
	public final mesh	as kri.Mesh
	public final va	= kri.vb.Array()
	public def constructor(m as kri.Mesh):
		mesh = m
		va.bind()
		m.vbo[0].initAll(-1)
	public def draw() as void:
		va.bind()
		mesh.draw(1)



#---------	POINT	---------#

public class Point( kri.Mesh ):
	public def constructor():
		super( BeginMode.Points )
		.nVert = .nPoly = 1
		vat = kri.vb.Attrib()
		vat.init(1)
		ai = kri.vb.Info( slot:kri.Ant.Inst.attribs.vertex,
			size:1, type:VertexAttribPointerType.UnsignedByte )
		vat.Semant.Add(ai)
		vbo.Add(vat)


#---------	QUAD	---------#

public class Quad( kri.Mesh ):
	public def constructor():
		super( BeginMode.TriangleStrip )
		self.nVert = 4
		self.nPoly = 4
		vat = kri.vb.Attrib()
		vat.init[of Vector2h]((of Vector2h:
			Vector2h(-1f,-1f),	Vector2h(1f,-1f),
			Vector2h(-1f,1f),	Vector2h(1f,1f),
			), false)
		ai = kri.vb.Info( slot:kri.Ant.Inst.attribs.vertex,
			size:2, type:VertexAttribPointerType.HalfFloat )
		vat.Semant.Add(ai)
		vbo.Add(vat)


#----	LINE OBJECT (-1,1)	----#

public class Line( kri.Mesh ):
	public def constructor():
		super( BeginMode.Lines )
		self.nVert = 2
		self.nPoly = 1
		data = (of Vector4: Vector4(-1f,0f,0f,1f), Vector4(1f,0f,0f,1f))
		vat = kri.vb.Attrib()
		vat.init( data, false )
		kri.Help.enrich( vat, 4, kri.Ant.Inst.attribs.vertex )
		vbo.Add(vat)



#----	PLANE OBJECT	----#
# param: half-size of sides

public class Plane( kri.Mesh ):
	public def constructor(scale as Vector2):
		con = Constructor( v:array[of Vertex](4) )
		sar = (-1f,1f)
		for i in range(4):
			con.v[i].pos = Vector4( scale.X * sar[i&1], scale.Y * sar[i>>1], 0f,1f)
			con.v[i].rot = Quaternion.Identity
		super( BeginMode.TriangleStrip )
		con.apply(self)

public class PlaneTex( kri.Mesh ):
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
		kri.Help.enrich( vat, 4, kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat )
		kri.Help.enrich( vat, 2, kri.Ant.Inst.attribs.tex[0] )
		# return
		vbo.Add(vat)
