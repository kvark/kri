namespace kri.ani

# Animation Interface
public interface IBase:
	def onFrame(time as double) as uint


public class Action(IBase):
	protected virtual def execute() as void:
		pass
	# more onTick than onFrame, a legacy name
	def IBase.onFrame(time as double) as uint:
		execute()
		return 1


public class Delta(IBase):
	private last	= 0.0
	private abstract def onDelta(delta as double) as uint:
		pass
	def IBase.onFrame(time as double) as uint:
		d = time - last
		last += d
		return onDelta(d)


public class Loop(IBase):
	public lTime	as double = 1.0
	private start	= double.MinValue
	[getter(Loops)]
	private loops	as uint = 1
	protected virtual def onLoop() as void:
		pass
	protected virtual def onRate(rate as double) as void:
		pass
	def IBase.onFrame(time as double) as uint:
		if time >= start+lTime:
			if not loops:
				onRate(1.0)
				return 1
			--loops
			start = time
			onLoop()
		else: onRate((time-start) / lTime)
		return 0
