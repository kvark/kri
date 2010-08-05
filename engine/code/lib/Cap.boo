namespace kri.lib

import OpenTK.Graphics.OpenGL

#-----------------------------------#
#	RENDER SYSTEM CAPABILITIES		#
#-----------------------------------#

public final class Capabilities:
	public final drawBuffers	as byte	
	public final multiSamples	as byte
	public final vertexAttribs	as byte
	public final colorAttaches	as byte
	public final textureUnits	as byte
	public final textureLayers	as ushort
	public final samplesColor	as ushort
	public final samplesInt		as ushort
	public final samplesDepth	as ushort
	public final elemIndices	as uint
	public final elemVertices	as uint
	public final contextVersion	as string
	public final shadingVersion	as string
	
	public static def Var(pn as GetPName) as int:
		val as int = -1
		GL.GetInteger(pn,val)
		return val
	
	public def constructor():
		contextVersion	= GL.GetString( StringName.Version )
		shadingVersion	= GL.GetString( StringName.ShadingLanguageVersion )
		drawBuffers		= Var( GetPName.MaxDrawBuffers )
		multiSamples	= Var( GetPName.MaxSamples )
		vertexAttribs	= Var( GetPName.MaxVertexAttribs )
		colorAttaches	= Var( GetPName.MaxColorAttachments )
		textureUnits	= Var( GetPName.MaxCombinedTextureImageUnits )
		textureLayers	= Var( GetPName.MaxArrayTextureLayers )
		samplesColor	= Var( GetPName.MaxColorTextureSamples )
		samplesInt		= Var( GetPName.MaxIntegerSamples )
		samplesDepth	= Var( GetPName.MaxDepthTextureSamples )
		elemIndices		= Var( GetPName.MaxElementsIndices )
		elemVertices	= Var( GetPName.MaxElementsVertices )
