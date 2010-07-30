namespace kri.load

import System
import System.Collections.Generic
import OpenTK


[StructLayout(LayoutKind.Sequential)]
public struct ColorRaw:
	public red		as byte
	public green	as byte
	public blue		as byte


#------		LOAD ATOM		------#

public class Atom:
	public final scene		as kri.Scene
	public final nodes		= Dictionary[of string,kri.Node]()
	public final mats		= Dictionary[of string,kri.Material]()
	
	public def constructor(name as string):
		scene = kri.Scene(name)
		nodes[''] = null


#------		NATIVE LOADER		------#

public class Native( kri.res.ILoaderGen[of Atom] ):
	public final readers	= Dictionary[of string,callable(Reader) as bool]()
	public final skipped	= Dictionary[of string,uint]()
	public final resMan		= kri.res.Manager()
	
	public final swImage	= kri.res.Switch[of kri.Texture]()
	public final swSound	= kri.res.Switch[of kri.sound.Buffer]()
	
	public def constructor():
		swImage.ext['.tga'] = image.Targa()
		swSound.ext['.wav'] = sound.Wave()
		resMan.register( swImage )
		resMan.register( swSound )
		# attach extensions
		readers['kri']	= p_sign
		readers['grav']	= p_grav
		for ext in kri.Ant.Inst.extensions:
			ext.attach(self)

	public def read(path as string) as Atom:
		kri.res.Manager.Check(path)
		rd = Reader(path,resMan)
		bs = rd.bin.BaseStream
		while bs.Position != bs.Length:
			name = rd.getString(8)
			size = rd.bin.ReadUInt32()
			size += bs.Position
			assert size <= bs.Length
			#todo!
			#if name in sets.skipChunks:
			#	bs.Seek(size, IO.SeekOrigin.Begin)
			#	continue
			p as callable(Reader) as bool = null
			if readers.TryGetValue(name,p) and p(rd):
				assert bs.Position == size
			else:
				skipped[name] = size
				bs.Seek(size, IO.SeekOrigin.Begin)
		return rd.finish()
	
	public def p_sign(r as Reader) as bool:
		ver = r.getByte()
		assert ver == 3 and r.Clear
		return true
	
	public def p_grav(r as Reader) as bool:
		r.at.scene.pGravity = pg = kri.shade.par.Value[of Vector4]('gravity')
		pg.Value = Vector4( r.getVector() )
		return true


#------		STANDARD EXTENSIONS PACK	------#

public class Standard( kri.IExtension ):
	public final objects	= ExObject()
	public final meshes		= ExMesh()
	public final materials	= ExMaterial()
	public final animations	= ExAnim()
	public final particles	= ExParticle()
	
	public def attach(nt as Native) as void:	#imp: kri.IExtension
		objects		.attach(nt)
		meshes		.attach(nt)
		materials	.attach(nt)
		animations	.attach(nt)
		particles	.attach(nt)
