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

public class Native( kri.data.ILoaderGen[of Atom] ):
	public final readers	= Dictionary[of string,callable(Reader) as bool]()
	public final skipped	= Dictionary[of string,uint]()
	public final resMan		= kri.data.Manager()
	
	public final swImage	= kri.data.Switch[of kri.Texture]()
	public final swSound	= kri.data.Switch[of kri.sound.Buffer]()
	
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

	public def read(path as string) as Atom:	#imp: kri.res.ILoaderGen
		kri.data.Manager.Check(path)
		rd = Reader(path,resMan)
		bs = rd.bin.BaseStream
		while bs.Position != bs.Length:
			name = rd.getString(8)
			size = rd.bin.ReadUInt32()
			size += bs.Position
			assert size <= bs.Length
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
	
	def kri.IExtension.attach(nt as Native) as void:
		for ex as kri.IExtension in (objects,meshes,materials,animations):
			ex.attach(nt)
