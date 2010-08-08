namespace support.vb
import System

public class Model( kri.res.ILoaderGen[of kri.Entity] ):
	public def read(path as string) as kri.Entity:	#imp: kri.res.ILoaderGen
		return null