namespace kri.load.image

import System.IO
import OpenTK.Graphics.OpenGL
import kri.data

public class Compress( ILoaderGen[of IGenerator[of kri.buf.Texture]]):
	public static final DdsMagic		= 0x20534444
	# header flags
	public static final FlagPixelFormat	= 0x00001000
	public static final FlagCaps		= 0x00000001
	public static final FlagMipCount	= 0x00020000
	# pixel format flagd
	public static final FlagFourCC		= 0x00000004
	
	private struct Header:
		public magic	as ulong
		public size		as ulong
		public flags	as ulong
		public height	as ulong
		public width	as ulong
		public pitch	as ulong
		public depth	as ulong
		public mips		as ulong
		public def check() as bool:
			return false	if magic != DdsMagic or size != 124
			return false	if not ((flags & FlagPixelFormat) | (flags & FlagCaps))
			return true
	
	private struct PixFormat:
		public size		as ulong
		public flags	as ulong
		public fourCC	as string
		public rgbBits	as ulong
		public maskR	as ulong
		public maskG	as ulong
		public maskB	as ulong
		public maskA	as ulong
	
	private struct Caps:
		public caps1	as ulong
		public caps2	as ulong
		public ddsx		as ulong
	
	public def read(path as string) as  IGenerator[of kri.buf.Texture]:	#imp: ILoaderGen
		br = BinaryReader( File.OpenRead(path) )
		head = Header(
			magic	: br.ReadUInt32(),
			size	: br.ReadUInt32(),
			flags	: br.ReadUInt32(),
			height	: br.ReadUInt32(),
			width	: br.ReadUInt32(),
			pitch	: br.ReadUInt32(),
			depth	: br.ReadUInt32(),
			mips	: br.ReadUInt32())
		br.BaseStream.Seek(44, SeekOrigin.Current)
		format = PixFormat(
			size	: br.ReadUInt32(),
			flags	: br.ReadUInt32(),
			fourCC	: string(br.ReadChars(4)),
			rgbBits	: br.ReadUInt32(),
			maskR	: br.ReadUInt32(),
			maskG	: br.ReadUInt32(),
			maskB	: br.ReadUInt32(),
			maskA	: br.ReadUInt32())
		Caps(
			caps1	: br.ReadUInt32(),
			caps2	: br.ReadUInt32(),
			ddsx	: br.ReadUInt32())
		br.BaseStream.Seek(8, SeekOrigin.Current)
		if not head.check():
			kri.lib.Journal.Log("DDS: bad format (${path})")
			return null
		t = kri.buf.Texture()
		t.wid = head.width
		t.het = head.height
		block = 0
		if (format.flags & FlagFourCC):
			if format.fourCC == 'DXT1':
				t.intFormat = PixelInternalFormat.CompressedRgbaS3tcDxt1Ext
				block = 8
			if format.fourCC == 'DXT3':
				t.intFormat = PixelInternalFormat.CompressedRgbaS3tcDxt3Ext
				block = 16
			if format.fourCC == 'DXT5':
				t.intFormat = PixelInternalFormat.CompressedRgbaS3tcDxt5Ext
				block = 16
		else: return null
		size = ((head.width+3)>>2) * ((head.height+3)>>2) * block
		assert size == head.pitch
		nMips = 1
		if (head.flags & FlagMipCount):
			nMips = head.mips
		for i in range(nMips):
			data = br.ReadBytes(size)
			t.initCompressed(data)
			t.switchLevel(i+1)
			size = ((t.wid+3)>>2) * ((t.het+3)>>2) * block
		t.switchLevel(0)
		return Dummy( tex:t )
