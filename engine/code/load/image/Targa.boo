namespace kri.load.image

import System.IO
import OpenTK.Graphics.OpenGL


public class Targa:
	private struct Header:
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

	public static def Get(str as string) as Basic:
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
		return Basic( str, hd.wid, hd.het,						\
			br.ReadBytes( hd.wid * hd.het * (hd.bits>>3) ),		\
			(PixelFormat.Bgr, PixelFormat.Bgra)[ hd.descr>>3 ]	\
			)
