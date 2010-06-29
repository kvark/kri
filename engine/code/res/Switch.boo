namespace kri.res

import System.Collections.Generic


public interface IGenerator[of T]:
	def generate() as T


public class Switch[of T]( ILoaderGen[of T] ):
	public final ext	= Dictionary[of string,ILoaderGen[of IGenerator[of T]]]()
	
	public def read(path as string) as T:	#imp: ILoaderGen
		Manager.Check(path)
		for dd in ext:
			if path.EndsWith(dd.Key):
				raw = dd.Value.read(path)
				return raw.generate()
		assert not 'valid extension'
		return null as T
