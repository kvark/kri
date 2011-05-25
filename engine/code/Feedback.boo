namespace kri

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#-----------#
#	QUERY	#
#-----------#

public class Catcher( System.IDisposable ):
	public final t	as QueryTarget
	public def constructor(target as QueryTarget, q as Query):
		t = target
		Query.Assign(t,q)
	public virtual def Dispose() as void:
		Query.Assign(t,null)


public class Query:
	public	final handle	as int
	private	static	final	State	= Dictionary[of QueryTarget,Query]()
	public	static	def Assign(tg as QueryTarget, val as Query) as void:
		q as Query = null
		State.TryGetValue(tg,q)
		if val:	
			assert not q
			State[tg] = val
			GL.BeginQuery( tg, val.handle )
		elif q:
			State[tg] = null
			GL.EndQuery(tg)
	
	public def constructor():
		tmp = 0
		GL.GenQueries(1,tmp)
		handle = tmp
	def destructor():
		tmp = handle
		Help.safeKill({ GL.DeleteQueries(1,tmp) })
	public def catch(tg as QueryTarget) as Catcher:
		return Catcher(tg,self)
	public def result() as int:
		rez = 0
		GL.GetQueryObject(handle, GetQueryObjectParam.QueryResult, rez)
		return rez


#-----------------------#
#	TRANSFORM FEEDBACK	#
#-----------------------#

public class CatcherFeed(Catcher):
	public def constructor(q as Query, m as BeginFeedbackMode):
		GL.BeginTransformFeedback(m)
		super( QueryTarget.TransformFeedbackPrimitivesWritten, q )
	public override def Dispose() as void:
		super()
		GL.EndTransformFeedback()

public class TransFeedback(Query):
	public			final	mode	as BeginFeedbackMode
	public	static	final	Cache	= array[of vb.Object](8)
	public	static	final	Dummy	= TransFeedback(1)

	public def constructor(nv as byte):
		mode = (BeginFeedbackMode.Points, BeginFeedbackMode.Lines, BeginFeedbackMode.Triangles)[nv-1]
	
	public def catch() as Catcher:
		return CatcherFeed(self,mode)
	
	public static def Bind(*buffers as (vb.Object)) as bool:
		for i in range( buffers.Length ):
			bf = Cache[i] = buffers[i]
			hid = 0
			if bf:
				hid = bf.handle
				if not bf.Ready:
					return false
			GL.BindBufferBase( BufferTarget.TransformFeedbackBuffer, i, hid )
		for i in range( buffers.Length, Cache.Length ):
			Cache[i] = null
		return true
