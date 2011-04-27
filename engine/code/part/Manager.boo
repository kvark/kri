namespace kri.part

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager( kri.IMeshed ):
	public	final tf	= kri.TransFeedback(1)
	public	final va	= kri.vb.Array()
	public	final behos	= List[of Behavior]()
	public	final dict	= kri.shade.par.Dict()
	public	final mesh	= kri.Mesh( BeginMode.Points )

	public	final col_init		= kri.shade.Collector()
	public	final col_update	= kri.shade.Collector()

	private parTotal	= kri.shade.par.Value[of single]('part_total')
	public	Total	as uint:
		get: return mesh.nVert
	public	Ready	as bool:
		get: return col_init.Ready and col_update.Ready
	
	kri.IMeshed.Mesh as kri.Mesh:
		get: return mesh
	
	public def constructor(num as uint):
		mesh.nVert = num
		dict.var(parTotal)
	
	public def initMesh(m as kri.Mesh) as void:
		assert m and mesh.vbo.Count
		if m.vbo.Count:
			m.vbo[0].Semant.Clear()
		else:
			m.vbo.Add( kri.vb.Attrib() )
		m.nVert = Total
		m.vbo[0].Semant.AddRange( mesh.vbo[0].Semant )
		m.allocate()
	
	public def makeStandard(pc as Context) as void:
		#init
		col_init.root = pc.sh_init
		col_init.mets['init'] = kri.shade.DefMethod.Void
		#update
		col_update.root = pc.sh_root
		col_update.extra.Add( pc.sh_tool )
		col_update.mets['reset']	= kri.shade.DefMethod.Float
		col_update.mets['update']	= kri.shade.DefMethod.Float
	
	public def makeHair(pc as Context) as void:
		# collectors
		col_init.mets['init']		= kri.shade.DefMethod.Void
		col_update.mets['update']	= kri.shade.DefMethod.Float
		col_init.root	= pc.sh_fur_init
		col_update.root	= pc.sh_fur_root
		if not 'Attrib zero bug workaround':
			b2 = Behavior('/part/fur/dummy')
			kri.Help.enrich(b2, 2, 'sys')
			behos.Add(b2)
	
	public def seBeh[of T(Behavior)]() as T:
		for beh in behos:
			bt = beh as T
			return bt	if bt
		return null	as T

	public def init(pc as Context) as void:
		# collect attributes
		mesh.vbo.Clear()
		mesh.vbo.Add( vob = kri.vb.Attrib() )
		for b in behos:
			vob.Semant.AddRange( (b as kri.vb.ISemanted).Semant )
			b.link(dict)
		mesh.allocate()
		# collect shaders
		for col in (col_init,col_update):
			col.bu.clear()
			col.absorb[of Behavior](behos)
			col.compose( vob.Semant, dict, kri.Ant.Inst.dict )
	
	protected def process(pe as Emitter, bu as kri.shade.Bundle) as bool:
		if not pe.update():
			return false
		tf.Bind( mesh.vbo[0] )
		parTotal.Value = (0f, 1f / (Total-1))[ Total>1 ]
		using kri.Discarder(true):
			mesh.render( va, bu, pe.entries, 0, tf )
		if not 'Debug':
			ar = array[of single]( Total * mesh.vbo[0].unitSize() >>2 )
			mesh.vbo[0].read(ar)
		# swap data
		data = mesh.vbo[0]
		mesh.vbo[0] = pe.mesh.vbo[0]
		pe.mesh.vbo[0] = data
		return true

	public def opInit(pe as Emitter) as bool:
		return process( pe, col_init.bu )
	public def opTick(pe as Emitter) as bool:
		return process( pe, col_update.bu )
