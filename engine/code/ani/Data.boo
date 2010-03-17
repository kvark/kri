namespace kri.ani.data

public struct Key[of T(struct)]:
	public co as T
	public h0 as T
	public h1 as T
	public t as single

public interface IPlayer:
	pass

public interface IChannel:
	def update(pl as IPlayer, time as single) as void


public class Channel[of T(struct)](IChannel):
	public final kar	as (Key[of T])
	public final fun	as callable(IPlayer,T)
	public bezier		as bool	= true
	public extrapolate	as bool	= false

	public def constructor(num as int, f as callable(IPlayer,T)):
		assert num>0
		kar = array[of Key[of T]](num)
		fun = f

	public abstract def lerp(ref a as T, ref b as T, t as single) as T:
		pass
	def IChannel.update(pl as IPlayer, time as single) as void:
		fun(pl, moment(time))
	
	public def moment(time as single) as T:
		i = System.Array.FindIndex(kar) do(k as Key[of T]):
			# ref causes BOO-1289
			return k.t > time
		if i<=0:
			a = kar[i]
			if extrapolate:
				if i: return lerp(a.co, a.h1, time - a.t)
				else: return lerp(a.co, a.h0, a.t - time)
			return a.co
		a,b = kar[i-1],kar[i]
		t = (time - a.t) / (b.t - a.t)
		if bezier:
			a1 = lerp(a.co, a.h1, t)
			b1 = lerp(b.h0, b.co, t)
			return lerp(a1, b1, t)
		return lerp(a.co, b.co, t)


public class Record:
	public final name		as string
	public final length		as single
	public final channels	= List[of IChannel]()
	public def constructor(str as string, t as single):
		name,length = str,t


public class Anim( kri.ani.IBase ):
	private final player	as IPlayer
	private final record	as Record
	
	public def constructor(pl as IPlayer, rec as Record):
		player,record = pl,rec
	
	private virtual def update() as uint:
		return 0
		
	def kri.ani.IBase.onFrame(time as double) as uint:
		return 2	if not record
		return 1	if time > record.length
		for c in record.channels:
			c.update(player,time)
		return update()
