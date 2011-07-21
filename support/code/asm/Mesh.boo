namespace support.asm

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Range:
	public	start	as uint
	public	total	as uint
	public	static	final	Zero = Range( start:0, total:0 )
	public def constructor(tm as kri.TagMat):
		start = tm.off
		total = tm.num


private class VarBuffer( kri.vb.IBuffed ):
	public	data	as kri.vb.Object	= null
	kri.vb.IBuffed.Data		as kri.vb.Object:
		get: return data

private class IndexAccum( kri.vb.Object ):
	public	MaxElements	as uint:
		get: return Allocated>>2
	public	curNumber	as uint	= 0

	public def bindOut(tf as kri.TransFeedback, np as uint) as void:
		tf.Cache[0] = self
		bindAsDestination(0, System.IntPtr(curNumber<<2), System.IntPtr(np<<2))



public class Mesh:
	public	final	data	= kri.vb.Attrib()
	public	final	eMap	= Dictionary[of kri.Mesh,Range]()
	public	final	buData	= kri.shade.Bundle()
	public	final	buInd	= kri.shade.Bundle()
	private	final	tf		= kri.TransFeedback(1)
	private	final	vDic	= kri.vb.Dict()
	private	final	varBuf	= VarBuffer()
	private	final	vao		= kri.vb.Array()
	private	final	pIndex	= kri.shade.par.Value[of int]('index')
	private	final	pOffset	= kri.shade.par.Value[of int]('offset')
	public			nVert	as uint	= 0
	public	final	maxVert	as uint	= 0
	
	public	Count	as int:
		get: return pIndex.Value
	
	public def constructor(nv as uint):
		clear()
		ai	= kri.vb.Info( name:'index', size:1,
			type:VertexAttribPointerType.UnsignedInt,
			integer:true )
		# init data buffer
		maxVert = nv
		kri.Help.enrich(data,4,'vertex','quat','tex')
		data.Semant.Add(ai)
		data.initUnit(maxVert)
		# make input dictionary
		ai.type = VertexAttribPointerType.UnsignedShort
		vDic.add( varBuf, ai, 0,0 )
		# prepare shader dictionary
		d = kri.shade.par.Dict()
		d.var(pIndex,pOffset)
		# make data compose shader
		sa = buData.shader
		sa.add('/asm/copy/data_v')
		sa.feedback(false,'to_vertex','to_quat','to_tex','to_index')
		# make index copy shader
		sa = buInd.shader
		sa.add('/asm/copy/ind_v')
		sa.attrib( 8, ai.name )	# better chaching in VAO
		sa.feedback(false,'to_index')
		# common routines
		for bu in (buData,buInd):
			bu.dicts.Add(d)
			bu.link()
	
	public def clear() as void:
		eMap.Clear()
		nVert = 0
		pIndex.Value = 0
	
	public def copyData(m as kri.Mesh) as Range:
		r = Range.Zero
		if eMap.TryGetValue(m,r):
			return r
		# copy vertex data
		if nVert+m.nVert > maxVert:
			kri.lib.Journal.Log("Asm: vertex buffer overflow (${m.nVert})")
			return r
		tf.Cache[0] = data
		data.bindAsDestination(0, nVert, m.nVert)
		m.fillEntries(vDic)
		vDic.fake('tex0','tex1')
		if m.render( vao, buData, vDic, 1,tf ):
			r.start = nVert
			r.total = m.nVert
			pIndex.Value += 1
			nVert += m.nVert
		eMap.Add(m,r)
		return r

	public def copyIndex(m as kri.Mesh, out as IndexAccum, tm as kri.TagMat) as bool:
		if not (m.ind and out):	return false
		rv = Range.Zero
		if not eMap.TryGetValue(m,rv):
			kri.lib.Journal.Log('Asm: mesh not registered')
			return false
		pOffset.Value = rv.start
		if out.curNumber+m.nPoly > out.Allocated:
			kri.lib.Journal.Log('Asm: index buffer overflow')
			return false
		varBuf.data = m.ind
		out.bindOut( tf, tm.num )
		if m.render( vao, buInd, vDic, tm.off, tm.num, 1,tf ):
			out.curNumber += tm.num
			return true
		return false
