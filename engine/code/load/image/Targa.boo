namespace kri.load.image

import System.IO


public class Targa:
	[getter(Result)]
	private final img as Basic
	struct Header:
		public magic	as (byte)
		public xrig		as ushort
		public yrig		as ushort
		public wid		as ushort
		public het		as ushort
		public bits		as byte
		public descr	as byte
		public def check() as bool:
			return false	if magic[0] or magic[1] or magic[2]!=2
			return false	if xrig + yrig or bits != 24 + descr
			return true

	public def constructor(str as string):
		kri.res.check(str)
		br = BinaryReader( File.OpenRead(str) )	
		hd = Header(
			magic:	br.ReadBytes(8),
			xrig:	br.ReadUInt16(),
			yrig:	br.ReadUInt16(),
			wid:	br.ReadUInt16(),
			het:	br.ReadUInt16(),
			bits:	br.ReadByte(),
			descr:	br.ReadByte() )
		assert hd.check()	
		img = Basic(str, hd.wid, hd.het)
		order = (2,1,0,3)
		for i in range(hd.wid*hd.het):
			data = br.ReadBytes( hd.bits>>8 )
			for j in range(order.Length):
				img.scan[(i<<2)+j] = data[order[j]]
			if not hd.descr:	# set alpha
				img.scan[(i<<2)+3] = 0xFF
