namespace support.vb

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics

public class Model( kri.res.ILoaderGen[of kri.Entity] ):
	public class Reader:
		public final bin	as IO.BinaryReader
		public final head	as Header
		public final ent	= kri.Entity()
		public def constructor(path as string):
			bin = IO.BinaryReader( IO.File.OpenRead(path) )
			head = Header(self)
		public def finish() as kri.Entity:
			bin.Close()
			return ent
		public def getByte() as byte:
			return bin.ReadByte()
		public def getLong() as long:
			return bin.ReadInt32()
		public def getReal() as single:
			return bin.ReadSingle()
		public def getString() as string:
			size = bin.ReadUInt16()
			return string( bin.ReadChars(size) )
		public def getColor() as Color4:
			ar = List[of single]( bin.ReadSingle()	for i in range(4) ).ToArray()
			return Color4(ar[0],ar[1],ar[3],ar[3])

	public struct Header:
		public sign			as string
		public formatVer	as int
		private unk0		as byte
		private unk1		as (byte)
		public globalScale	as single
		public coordScale	as single
		public coordName	as string
		private unk2		as byte
		private unk3		as ulong

		public def constructor(rd as Reader):
			.sign = string( rd.bin.ReadChars(8) )
			.unk0 = rd.getByte()
			.formatVer = (0,1)[unk0==3]
			.unk1 = rd.bin.ReadBytes( (4,2)[formatVer] )
			.globalScale = rd.getReal()
			.coordScale = rd.getReal()
			.coordName = rd.getString()
			.unk2 = rd.getByte()
			.unk3 = rd.getLong()

	public def getMaterials(rd as Reader) as bool:
		mid		= rd.getString()
		name	= rd.getString()
		# read mat
		m = kri.Material(name)
		# read the rest
		blend = rd.getString()
		mtype = rd.getString()
		flag1 = rd.getLong()
		flag2 = rd.getLong()
		blend = mtype = ''
		flag1 = flag2 = 0
		return true

	public def getTextures(rd as Reader) as bool:
		return true

	public def getNodes(rd as Reader) as bool:
		return true

	public def getBones(rd as Reader) as bool:
		return true

	public def getVertices(rd as Reader) as bool:
		return true

	public static final Signature	= 'B3D 1.1 '


	public def read(path as string) as kri.Entity:	#imp: kri.res.ILoaderGen
		kri.res.Manager.Check(path)
		rd = Reader(path)
		port = Dictionary[of byte,callable(Reader) as bool]()
		port[0x7] = getMaterials
		port[0x8] = getTextures
		port[0xA] = getNodes
		port[0xE] = getBones
		port[0xF] = getVertices
		bs = rd.bin.BaseStream
		while bs.Position != bs.Length:
			code = rd.getByte()
			fun = port[code]
			assert fun(rd)
		return rd.finish()
