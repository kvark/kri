namespace kri.rend

import System
import System.Collections.Generic


private class Job:
	public difficulty	as int		= 1
	public onGPU		as bool		= true
	public toScreen		as bool		= false
	public rend			as Basic	= null
	public final deps	= List[of Job]()


public class Manager(Basic):
	private	final	jall	= Dictionary[of string,Job]()
	private final	ln		= link.Buffer(0,0,0)
	private	final	reverse		= false
	private final	static MAX	= 100
	
	public def constructor(rev as bool):
		super(false)
		reverse = rev
	
	public def add(name as string, dif as int, r as Basic, *deps as (string)) as void:
		assert not name in jall	# ensures no cycles in the dependency graph
		jall[name] = j = Job( difficulty:Math.Abs(dif), onGPU:true, toScreen:dif>0, rend:r )
		for d in deps:
			j.deps.Add( jall[d] )
	
	public override def setup(pl as kri.buf.Plane) as bool:
		ln.resize(pl)
		return List[of Job](jall.Values).TrueForAll() do(j as Job):
			return j.rend.setup(pl)
	
	public override def process(con as link.Basic) as void:
		jord = List[of Job]( j for j in jall.Values if j.rend.active ).ToArray()
		total = 0
		for j in jord:
			total += j.difficulty
		assert jord.Length <= MAX
		# aux func
		def getScore() as int:	# O(n^3)
			mint,sum = total,0
			for i in range(jord.Length):
				rd = -1
				for d in jord[i].deps:
					ind = Array.IndexOf(jord,d)
					assert ind >= 0 and ind != i
					rd = Math.Max(ind,rd)
				continue	if rd<0
				cur,step = 0,(1 if rd<i else -1)
				rd += (step+1)>>1
				for k in range(rd,i,step):
					cur += step*jord[k].difficulty
				if cur<mint:	mint = cur
				sum += cur
			return mint*MAX*MAX + sum
		def swap(i as int) as void:	# O(1)
			j = jord[i-1]
			jord[i-1] = jord[i]
			jord[i] = j
		# main proc
		score = array[of int]( jord.Length )
		score[0] = getScore()
		while true:	# O(n^6) !!!
			md = 0
			for i in range(1, jord.Length):
				swap(i)
				score[i] = getScore()
				md=i	if score[i]>score[md]
				swap(i)
			break	if not md
			swap(md)
			score[0] = score[md]
		assert score[0] >= 0
		# run
		Array.Reverse(jord)	if reverse
		for j in jord:
			j.rend.process(ln)
		ln.blitTo(con)
