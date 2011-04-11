namespace kri.lib

import OpenTK
import kri.shade

public interface ILogger:
	def log(str as string) as void
	
public class Journal(ILogger):
	public	static	Inst		as ILogger	= null
	public	final	messages	= List[of string]()
	def ILogger.log(str as string) as void:
		messages.Add(str)
	public static def Log(str as string) as void:
		if Inst:
			Inst.log(str)
	public def flush() as string:
		if not messages.Count:
			return null
		rez = string.Join("\n",messages.ToArray())
		messages.Clear()
		return rez
	

# Shader Parameter Library
public final class Param:
	public final modelView	= par.spa.Shared('s_model')	# object->world
	public final light		= par.Light()
	public final pLit		= par.Project('lit')	# light->world, projection
	public final pCam		= par.Project('cam')	# camera->world, projection
	public final parSize	= par.Value[of Vector4]('screen_size')	# viewport size
	public final parTime	= par.Value[of Vector4]('cur_time')		# task time & delta
	
	public def activate(c as kri.Camera) as void:
		kri.Camera.Current = c
		pCam.activate(c)	if c
	public def activate(l as kri.Light) as void:
		light.activate(l)
		pLit.activate(l)
	public def activate(pl as kri.buf.Plane) as void:
		parSize.Value = Vector4( 1f*pl.wid, 1f*pl.het, 0.5f*(pl.wid+pl.het), 0f)
		
	public def constructor(d as par.Dict):
		for me in (of kri.meta.IBase: modelView,light,pLit,pCam):
			me.link(d)
		d.var(parSize,parTime)
