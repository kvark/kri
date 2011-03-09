//
//  render.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-28.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "render.h"

#include <OpenGLES/ES2/gl.h>


namespace kri	{
namespace ren	{
	typedef void (GL_APIENTRY *fun)(GLsizei,GLuint*);

	template<fun F>
	GLuint generate()	{
		GLuint id = 0;
		F(1,&id);
		return id;
	}

	// Abstract rendering surface	//

	Surface::Surface()
	{}

	Surface::~Surface()
	{}


	// Render frame	//

	const Frame&	Frame::Default		= *static_cast<const Frame*>(0);

	Frame::Frame()
	: mHardId( generate<glGenFramebuffers>() )
	{}

	Frame::~Frame()	{
		glDeleteFramebuffers(1,&mHardId);
	}

	void Frame::bind() const	{
		glBindFramebuffer( GL_FRAMEBUFFER, mHardId );
	}


	// Render target	//

	Target::Target()
	{}

	Target::~Target()
	{}

	void Target::addSurface(int slot, PSurface &pCur, const PSurface &pNew) const	{
		if(pCur.get() == pNew.get())
			return;
		if(!pNew.get())
			glFramebufferRenderbuffer( GL_FRAMEBUFFER, slot, GL_RENDERBUFFER, 0 );
		else
			pNew->bindTo(slot);
		pCur = pNew;
	}

	void Target::use(int mask)	{
		bind();
		addSurface(GL_STENCIL_ATTACHMENT,		state.pStencil,		pStencil	);
		addSurface(GL_DEPTH_ATTACHMENT,			state.pDepth,		pDepth		);
		for(unsigned i=0; i!=NUM_COLORS; ++i)
			addSurface(GL_COLOR_ATTACHMENT0+i,	state.pColor[i],	pColor[i]	);
	}


	// Render buffer	//

	const Buffer&	Buffer::Default		= *static_cast<const Buffer*>(0);
	
	Buffer::Buffer()
	: mHardId( generate<glGenRenderbuffers>() )
	{}

	Buffer::~Buffer()	{
		glDeleteRenderbuffers(1,&mHardId);
	}

	void Buffer::bind() const	{
		glBindRenderbuffer( GL_RENDERBUFFER, this ? mHardId : 0 );
	}
	
	void Buffer::bindTo(int slot) const	{
		bind();
		glFramebufferRenderbuffer( GL_FRAMEBUFFER, slot, GL_RENDERBUFFER, mHardId );
	}

	
	// Texture	//

	const Texture&	Texture::Default	= *static_cast<const Texture*>(0);

	void Texture::Channel(unsigned tid)	{
		glActiveTexture(GL_TEXTURE0+tid);
	}

	void Texture::Init(unsigned wid, unsigned het, int bits, const void *data)	{
		const GLenum format = (bits==8 ? GL_ALPHA : (bits>24 ? GL_RGBA : GL_RGB));
		glTexImage2D( GL_TEXTURE_2D, 0, format, wid, het, 0,
			format, GL_UNSIGNED_BYTE, data );
		const GLenum err = glGetError();
		assert(err == GL_NONE);
	}

	Texture::Texture()
	: mHardId( generate<glGenTextures>() )
	{}

	Texture::~Texture()	{
		glDeleteTextures(1,&mHardId);
	}
	
	void Texture::bind() const	{
		glBindTexture(GL_TEXTURE_2D, mHardId);
	}

	void Texture::bindTo(int slot) const	{
		glFramebufferTexture2D( GL_FRAMEBUFFER, slot, GL_TEXTURE_2D, mHardId, 0 );
	}

}//ren
}//kri
