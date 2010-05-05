namespace kri.load

public partial class Native:
	protected def getProjector(p as kri.Projector) as void:
		p.rangeIn	= getReal()
		p.rangeOut	= getReal()
		p.fov		= getReal() * 0.5f

	#---	Parse entity	---#
	public def p_entity() as bool:
		off,n = 0,0
		m = geData[of kri.Mesh]()
		node = geData[of kri.Node]()
		return false	if not m or not node
		e = kri.Entity( node:node, mesh:m )
		at.scene.entities.Add(e)
		puData(e)
		while true:
			n = br.ReadUInt16()
			break	if not n
			e.tags.Add( kri.TagMat( off:off, num:n,
				mat: at.mats[ getString() ] ))
			off += n
		if (n = m.nPoly - off) > 0:
			e.tags.Add( kri.TagMat(off:off, num:n, mat:con.mDef ))
		return true
	
	#---	Parse spatial node	---#
	public def p_node() as bool:
		n = kri.Node( getString() )
		at.nodes[n.name] = n
		puData(n)
		n.Parent = at.nodes[ getString() ]
		n.local = getSpatial()	# touched by Parent
		return true
	
	#---	Parse camera	---#
	public def p_cam() as bool:
		n = geData[of kri.Node]()
		return false	if not n
		c = kri.Camera( node:n )
		puData(c)
		br.ReadByte()	# is current
		getProjector(c)
		at.scene.cameras.Add(c)
		return true

	#---	Parse light source	---#
	public def p_lamp() as bool:
		n = geData[of kri.Node]()
		return false	if not n
		l = kri.Light( node:n )
		puData(l)
		l.Color	= getColorByte()
		# attenuation
		l.energy	= getReal()
		l.quad1		= getReal()
		l.quad2		= getReal()
		l.sphere	= getReal()
		# main
		type = getString()
		getProjector(l)
		if type == 'SUN':
			l.makeOrtho( l.fov )
		elif type == 'POINT':
			l.fov = 0f
		l.softness	= getReal()
		at.scene.lights.Add(l)
		return true
	
	#---	Parse skeleton	---#
	public def p_skel() as bool:
		node = geData[of kri.Node]()
		return false	if not node
		nbones = br.ReadByte()
		s = kri.Skeleton( node,nbones )
		puData(s)
		# read nodes
		par = array[of byte](nbones)
		for i in range(nbones):
			name = getString()
			par[i] = br.ReadByte()
			s.bones[i] = kri.NodeBone(name, getSpatial())
		for i in range(nbones):
			s.bones[i].Parent = (s.bones[par[i]-1] if par[i] else node)
		s.bakePoseData(node)
		return true
	
	#------	PHYSICS	------#
	
	#---	Parse collision bounds	---#
	public def p_collide() as bool:
		getReal()	# margin
		getString()	# type
		return true
	
	#---	Parse static body	---#
	public def pb_stat() as bool:
		br.ReadBytes(2)	# actor,reacts
		return true
	
	#---	Parse rigid body	---#
	public def pb_rigid() as bool:
		br.ReadBytes(2)	# actor,reacts
		getReal()	# mass
		getReal()	# radius
		getReal()	# form factor
		getReal()	# moving damping
		getReal()	# rotation damping
		return true
