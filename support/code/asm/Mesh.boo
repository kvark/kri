namespace support.asm

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


private struct Range:
	public	start	as uint
	public	total	as uint

private struct Reference:
	public	vert	as Range
	public	final	ind	as List[of Range]
	public def constructor(r as Range):
		vert = r
		ind = List[of Range]()


private class VarBuffer( kri.vb.IBuffed ):
	public	data	as kri.vb.Object	= null
	kri.vb.IBuffed.Data		as kri.vb.Object:
		get: return data



public class Mesh:
	public	final	eMap	= Dictionary[of kri.Mesh,Reference]()
	private	final	tf		= kri.TransFeedback(1)
	public	final	buData	= kri.shade.Bundle()
	public	final	buInd	= kri.shade.Bundle()
	private	final	vDic	= kri.vb.Dict()
	private	final	varBuf	= VarBuffer()
	private	final	vao		= kri.vb.Array()
	private	final	pOffset	= kri.shade.par.Value[of int]('offset')
	
	public def constructor():
		# make input dictionary
		ai	= kri.vb.Info( name:'index', size:1,
			type:VertexAttribPointerType.UnsignedShort,
			integer:true )
		vDic.add( varBuf, ai, 0,0 )
		# prepare shader dictionary
		d = kri.shade.par.Dict()
		d.var(pOffset)
		# make data compose shader
		sa = buData.shader
		sa.add('/asm/copy/data_v')
		sa.feedback(false,'to_vertex','to_quat','to_tex')
		# make index copy shader
		sa = buInd.shader
		sa.add('/asm/copy/ind_v')
		sa.attrib( 8, ai.name )	# better chaching in VAO
		sa.feedback(false,'to_index')
		# common routines
		for bu in (buData,buInd):
			bu.dicts.Add(d)
			bu.link()
	
	public def add(m as kri.Mesh, out as kri.Mesh) as void:
		pOffset.Value = out.nVert
		# copy vertex data
		tf.Bind( out.buffers[0] )
		m.render( vao, buData, tf )
		out.nVert += m.nVert
		# copy indices
		varBuf.data = m.ind
		tf.Bind( out.ind )
		m.render( vao, buInd, vDic, 1,tf )
		out.nPoly += m.nPoly

