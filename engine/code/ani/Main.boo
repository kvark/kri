namespace kri.ani

# Animation Interface
public interface IBase:
	def onFrame(time as double) as uint


public class Action(IBase):
	protected virtual def execute() as void:
		pass
	def IBase.onFrame(time as double) as uint:
		execute()
		return 1


public class Delta(IBase):
	private last	= kri.Ant.Inst.Time
	private abstract def onDelta(delta as double) as uint:
		pass
	def IBase.onFrame(time as double) as uint:
		last += (d = time - last)
		return onDelta(d)


public class Loop(IBase):
	public lTime	as double = 1.0
	private start	= 0.0
	[getter(Loops)]
	private loops	as int = -1
	private virtual def onLoop() as void:
		pass
	private virtual def onRate(rate as double) as uint:
		return 0
	def IBase.onFrame(time as double) as uint:
		if time > start+lTime:
			++loops
			start = time
			onLoop()
		return onRate((time-start) / lTime)
