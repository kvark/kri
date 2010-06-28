﻿namespace kri.load.image

import System.IO
import OpenTK.Graphics.OpenGL


public class Targa( kri.res.ILoaderGen[of Basic] ):
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

	public def read(path as string) as Basic:
		kri.res.Manager.Check(path)
		br = BinaryReader( File.OpenRead(path) )	
		hd = Header(
			magic	: br.ReadBytes(8),
			xrig	: br.ReadUInt16(),
			yrig	: br.ReadUInt16(),
			wid		: br.ReadUInt16(),
			het		: br.ReadUInt16(),
			bits	: br.ReadByte(),
			descr	: br.ReadByte() )
		assert hd.check()
		
		data = br.ReadBytes( hd.wid * hd.het * (hd.bits>>3) )
		fmt = (PixelFormat.Bgr, PixelFormat.Bgra)[ hd.descr>>3 ]
		return Basic( path, hd.wid, hd.het, data, fmt )
