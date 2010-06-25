namespace kri.load.sound

import System.IO

public class Wave:
	public static def Get(str as string) as Basic:
		using br = BinaryReader( File.OpenRead(str) ):
			signature = string(br.ReadChars(4))
			assert signature == 'RIFF'
			riffChunkSize = br.ReadInt32()
			format = string(br.ReadChars(4))
			assert format == 'WAVE'
			fmSignature = string(br.ReadChars(4))
			assert fmSignature == 'fmt '
			formatChunkSize = br.ReadInt32()
			audioFormat = br.ReadInt16()
			numChannels = br.ReadInt16()
			sampleRate = br.ReadInt32()
			byteRate = br.ReadInt32()
			blockAlign = br.ReadInt16()
			bitsPerSample = br.ReadInt16()
			dataSignature = string(br.ReadChars(4))
			assert dataSignature == 'data'
			dataSize = br.ReadInt32()
			data = br.ReadBytes(dataSize)
		return Basic(numChannels, bitsPerSample, sampleRate, data)
