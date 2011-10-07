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
	# help members
	private	final	buffer	= array[of byte](16)
	
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
	
	private def flipVertical(data as (byte), het as uint, block as uint) as void:
		v as System.UInt64 = 0
		hasAlpha = block>8
		if het<=1:	return
		if het==2:
			i=0
			while i<data.Length:
				if hasAlpha:
					v = (data[i+2]<<16) + (data[i+1]<<8) + data[i]
					data[i+0] = (v>>12)&0xFF
					data[i+1] = ((v>>20)&0xF) + ((v&0xF)<<4)
					data[i+2] = (v>>4)&0xFF
					i += 8
				x = data[i+4]
				data[i+4] = data[i+5]
				data[i+5] = x
				i += 8
			return
		totalBlocks = data.Length / block
		vertiBlocks = ((het+3)>>2)
		horisBlocks = totalBlocks / vertiBlocks
		assert vertiBlocks * horisBlocks == totalBlocks
		for j in range (vertiBlocks>>1):
			for i in range(horisBlocks):
				a = block * (horisBlocks*j+i)
				b = block * (horisBlocks*(vertiBlocks-j-1)+i)
				System.Buffer.BlockCopy(data, a, buffer, 0, block)
				System.Buffer.BlockCopy(data, b, data, a, block)
				System.Buffer.BlockCopy(buffer, 0, data, b, block)
		i=0
		while i<data.Length:
			if hasAlpha:
				v = 0
				v += (data[i+7]<<16) + (data[i+6]<<8) + data[i+5]
				v <<= 24
				v += (data[i+4]<<16) + (data[i+3]<<8) + data[i+2]
				data[i+2] = (v>>36)&0xFF
				data[i+3] = ((v>>44)&0xF) + (((v>>24)&0xF)<<4)
				data[i+4] = (v>>28)&0xFF
				data[i+5] = (v>>12)&0xFF
				data[i+6] = ((v>>20)&0xF) + (((v>>0)&0xF)<<4)
				data[i+7] = (v>>4)&0xFF
				i += 8
			x = data[i+4]
			data[i+4] = data[i+7]
			data[i+7] = x
			x = data[i+5]
			data[i+5] = data[i+6]
			data[i+6] = x
			i += 8
	
	public def read(path as string) as  IGenerator[of kri.buf.Texture]:	#imp: ILoaderGen
		br = BinaryReader( File.OpenRead(path) )
		# read header
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
		# read pixel format
		format = PixFormat(
			size	: br.ReadUInt32(),
			flags	: br.ReadUInt32(),
			fourCC	: string(br.ReadChars(4)),
			rgbBits	: br.ReadUInt32(),
			maskR	: br.ReadUInt32(),
			maskG	: br.ReadUInt32(),
			maskB	: br.ReadUInt32(),
			maskA	: br.ReadUInt32())
		br.BaseStream.Seek(20, SeekOrigin.Current)
		# check input and init texture
		if not head.check():
			kri.lib.Journal.Log("DDS: bad format (${path})")
			return null
		t = kri.buf.Texture()
		t.wid = head.width
		t.het = head.height
		# find internal format and block size
		block = 0
		if (format.flags & FlagFourCC):
			id = System.Array.IndexOf( ('DXT1','DXT3','DXT5'), format.fourCC )
			block = (8,16,16)[id]
			pif0 = (PixelInternalFormat.CompressedRgbaS3tcDxt1Ext,
					PixelInternalFormat.CompressedRgbaS3tcDxt3Ext,
					PixelInternalFormat.CompressedRgbaS3tcDxt5Ext)
			pif1 = (PixelInternalFormat.CompressedSrgbAlphaS3tcDxt1Ext,
					PixelInternalFormat.CompressedSrgbAlphaS3tcDxt3Ext,
					PixelInternalFormat.CompressedSrgbAlphaS3tcDxt5Ext)
			gc = Basic.GammaCorrected and kri.Ant.Inst.gamma
			t.intFormat = (pif0,pif1)[gc][id]
		else:
			kri.lib.Journal.Log("DDS: non-compressed (${path})")
			return null
		# fill up the mip maps
		size = ((head.width+3)>>2) * ((head.height+3)>>2) * block
		if size != head.pitch:
			kri.lib.Journal.Log("DDS: invalid size (${path}: ${size} != ${head.pitch})")
			return null
		nMips = 1
		if (head.flags & FlagMipCount):
			nMips = head.mips
		for i in range(nMips):
			data = br.ReadBytes(size)
			flipVertical(data, t.het, block)
			t.init(data,true)
			t.switchLevel(i+1)
			size = ((t.wid+3)>>2) * ((t.het+3)>>2) * block
		# pass-through result
		t.switchLevel(0)
		t.filt(true,true)
		return Dummy( tex:t )
