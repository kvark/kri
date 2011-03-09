//
//  shader.cpp
//  test_long
//
//  Created by Dart Veider on 10-11-16.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "asset.h"
#include "core.h"
#include "data.h"
#include "mesh.h"
#include "render.h"
#include "shader.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include <OpenGLES/ES2/gl.h>

namespace kri	{
namespace shade	{
	
	//		SHADER OBJECT		//
	
	Pointer<Object> Object::Load(const char* path)	{
		Pointer<Object> ptr;
		const int len = strlen(path);
		const char *const ext = path+len-4;
		GLenum type(0);
		if( ext<path )
			return ptr;
		else if( !strcmp(ext,".vsh") )
			type = GL_VERTEX_SHADER;
		else if( !strcmp(ext,".fsh") )
			type = GL_FRAGMENT_SHADER;
		else
			assert(!"valid extension");
		
		asset::CharBuffer buf = Core::Inst()->mResMan->read(path);
		if(!buf.get())
			return ptr;
		ptr = new Object(type);
		ptr->compile( buf->base );
		return ptr;
	}
	
	
	Object::Object(unsigned type)
	: mHardId( glCreateShader(type) )	{
		//empty
	}
		
	Object::~Object()	{
		glDeleteShader(mHardId);
	}

	bool Object::compile(const char *text)	{
		int length;
		glShaderSource(mHardId, 1, &text, NULL);
		glCompileShader(mHardId);
		//get log
		static char buf[512];
		glGetShaderInfoLog(mHardId, sizeof(buf)-1, &length, buf);
		buf[length] = 0;
		//exit
		if(!isCompiled())	{
			printf("Compile fail (%d):\n%s", mHardId, buf);
			return false;
		}else
			return true;
	}
	
	bool Object::isCompiled() const	{
		int status = -1;
		glGetShaderiv(mHardId, GL_COMPILE_STATUS, &status);
		return status != 0;
	}
	

	//		SHADER PROGRAM		//
	
	const Program& Program::Default = *(const Program*)0;
	
	Program::Program():
	mHardId( glCreateProgram() ), mStamp(0)
	{}
	
	Program::~Program()	{
		glDeleteProgram(mHardId);
	}
	
	void Program::attach(const Object &object)	{
		glAttachShader(mHardId, object.mHardId);
	}
    
	void Program::setInput(const char *const attribs[])	{
		for(int i=0; attribs[i]; ++i)	{
			glBindAttribLocation( mHardId, i, attribs[i] );
		}
	}
	
	bool Program::link()	{
		++mStamp;
		glLinkProgram(mHardId);
		//check status
		static char buf[1024];
		int length = 0;
		glGetProgramInfoLog(mHardId, sizeof(buf)-1, &length, buf);
		buf[length] = 0;
		if(!isLinked())	{
			printf("Link fail (%d):\n%s", mHardId, buf);
			return false;
		}else
			return true;
	}
	
	bool Program::fill(const char *const sources[])   {
        for(int i=0; sources[i]; ++i)    {
			Pointer<Object> pObj = Object::Load(sources[i]);
			if(!pObj)
				return false;
            attach(*pObj);
        }
		return link();
    }
	
	void Program::bind() const	{
		assert( isLinked() );
		glUseProgram( this ? mHardId:0 );
	}
	
	int Program::getUniform(const char *name)	{
		return glGetUniformLocation(mHardId, name);
	}
	
	bool Program::isLinked() const	{
		if(!this)
			return true;
		int status = -1;
		glGetProgramiv(mHardId, GL_LINK_STATUS, &status);
		return status != 0;
	}
	

	//		SHADER UNIFORM		//
	
	void Uniform::push(unsigned &tid) const	{
		if(!data)	//unused param
			return;
		typedef Pointer<ren::Texture>	PTexture;
		const GLint& di		= *static_cast<const GLint*>(data);
		const GLfloat& df	= *static_cast<const GLfloat*>(data);
		const PTexture& dt	= *static_cast<const PTexture*>(data);
		switch(type)	{
		case GL_FLOAT:
			glUniform1f(loc,df);
			break;
		case GL_INT:
			glUniform1i(loc,di);
			break;
		case GL_FLOAT_VEC4:
			glUniform4fv(loc,1,&df);
			break;
		case GL_INT_VEC4:
			glUniform4iv(loc,1,&di);
			break;
		case GL_FLOAT_MAT3:
			glUniformMatrix3fv(loc,1,false,&df);
			break;
		case GL_FLOAT_MAT4:
			glUniformMatrix4fv(loc,1,false,&df);
			break;
		case GL_SAMPLER_2D:
			glUniform1i(loc,tid);
			ren::Texture::Channel(tid);
			assert( dt.get() );
			dt->bind();
			++tid;
			break;
		default: assert(!"good type");
		}
	}


	//		SHADER BUNDLE		//

	Bundle::Bundle():
	mProgStamp(0),
	mProgram(new Program())	{
		//link to standard parameter dictionary
		mDictionaries.append()->data = Core::Inst()->mParams->getBook();
	}

	Bundle::Bundle(const Bundle& bun):
	mProgStamp(bun.mProgStamp),
	mProgram(bun.mProgram)	{
		mDictionaries = bun.mDictionaries;
	}

	Bundle::~Bundle()
	{}

	void Bundle::linkData(Uniform &uni)	{
		List<Unidict> *pDict = &mDictionaries;
		while( (pDict = pDict->next.get()) )	{
			for(unsigned i=0; i!=pDict->data.getSize(); ++i)	{
				const Unidata &pud = pDict->data[i];
				if( strcmp(pud.name,uni.name) )
					continue;
				assert( pud.type == uni.type && pud.num >= uni.num );
				uni.data = pud.data;
				return;
			}
		}
		assert(!"found uniform");
	}

	void Bundle::use()	{
		assert( mProgram.get() && mProgram->isLinked() );
		if (mProgStamp != mProgram->getStamp())
			sync();
		mProgram->bind();
		//bind parameters
		List<Uniform> *pu = &mUniforms;
		unsigned tid = 0;
		while((pu = pu->next.get()) != 0)
			pu->data.push(tid);
		assert(tid<=8);
		//check state
		const GLenum err = glGetError();
		assert(err == GL_NONE);
	}

	void Bundle::sync()	{
		assert( mProgram.get() );
		mProgStamp = mProgram->getStamp();
		//fill uniforms
		mUniforms.clear();
		List<Uniform> *pUni = &mUniforms;
		const unsigned hid = mProgram->getHardId();
		int total = -1;
		glGetProgramiv( hid, GL_ACTIVE_UNIFORMS, &total );
		for(int i=0; i<total; ++i)	{
			pUni = pUni->append().get();
			Uniform& uni = pUni->data;
			//read GL uniform
			int name_len=-1; GLenum type = GL_ZERO;
			glGetActiveUniform( hid, GLuint(i), sizeof(uni.name)-1,
				&name_len, &uni.num, &type, uni.name );
			uni.name[name_len] = 0;
			uni.loc = glGetUniformLocation( hid, uni.name );
			uni.type = type;
			//associate with data
			linkData(uni);
		}
		//fill attributes
		glGetProgramiv( hid, GL_ACTIVE_ATTRIBUTES, &total );
		mAttribs = new Array<Attrib>(total);
		for(int i=0; i<total; ++i)	{
			Attrib &at = (*mAttribs)[i];
			int name_len=-1; GLenum type = GL_ZERO;
			glGetActiveAttrib( hid, GLuint(i), sizeof(at.name)-1,
				&name_len, &at.num, &type, at.name);
			assert( at.num == 1 );
			assert( glGetAttribLocation(hid,at.name) == i );
			at.translate(type);
		}
	}

	const List<Uniform>	Bundle::getUniforms()	const	{
		return mUniforms;
	}
	ArrayRep<Attrib>	Bundle::getAttribs()	const	{
		return *mAttribs;
	}

}//shade
}//kri