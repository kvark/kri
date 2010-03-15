namespace kri.res

import System

public def check(path as string) as void:
	return if IO.File.Exists(path)
	print 'Unable to load ' + path
	raise 'Resource not found'
