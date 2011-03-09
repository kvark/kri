//
//  mesh.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-24.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "core.h"
#include "data.h"
#include "material.h"
#include "mesh.h"
#include "node.h"
#include "shader.h"

#include <assert.h>
#include <string.h>
#include <OpenGLES/ES2/gl.h>

namespace kri	{
	
	//		BUFFER OBJECT		//
	
	const BufferBase& BufferBase::Zero = *(Buffer*)0;
	
	unsigned BufferBase::GenerateId()	{
		unsigned id=0;
		glGenBuffers(1,&id);
		return id;
	}
	
	BufferBase::BufferBase():
	mHardId( GenerateId() )
	{}
	
	BufferBase::~BufferBase()	{
		glDeleteBuffers(1,&mHardId);
	}
	
	void BufferBase::bind(int target) const	{
		glBindBuffer(target, this ? mHardId:0 );
	}
	
	void BufferBase::Unbind(int target)	{
		assert(target);
		Zero.bind(target);
	}
	
	void BufferBase::init(int target, const void *const ptr, unsigned size)	{
		bind(target);
		glBufferData(target, size, ptr, GL_STATIC_DRAW);
	}

	
	//		BUFFER ATTRIBUTE	//
	
	unsigned Attrib::GetTypeSize(int tip)	{
		switch(tip)	{
			case GL_BYTE:
			case GL_UNSIGNED_BYTE:
				return 1;
			case GL_SHORT:
			case GL_UNSIGNED_SHORT:
				return 2;
			case GL_FLOAT:
			case GL_INT:
			case GL_UNSIGNED_INT:
				return 4;
			default:
				assert(!"good type");
				return 0;
		}
	}
	
	unsigned Attrib::getSize() const	{
		return num * GetTypeSize(type);
	}
	
	void Attrib::translate(int glType)	{
		type = glType;
		switch(glType)	{
			case GL_FLOAT:
			case GL_INT:
			case GL_BOOL:
				num=1; break;
			case GL_FLOAT_VEC2:
				num=2;	type=GL_FLOAT;
				break;
			case GL_FLOAT_VEC3:
				num=3;	type=GL_FLOAT;
				break;
			case GL_FLOAT_VEC4:
				num=4;	type=GL_FLOAT;
				break;
			case GL_INT_VEC2:
				num=2;	type=GL_INT;
				break;
			case GL_INT_VEC3:
				num=3;	type=GL_INT;
				break;
			case GL_INT_VEC4:
				num=4;	type=GL_INT;
				break;
			default:
				assert(!"known type");
		}
	}
	

	//		BUFFER WITH DATA	//
	
	static const Attrib AtZero = {0,0,0,false};
	
	Buffer::Buffer():
	mAttribs(AtZero)	{}
	
	unsigned Buffer::getStride() const	{
		unsigned stride = 0;
		const AtList *p = &mAttribs;
		while( (p = p->next.get()) != 0 )
			stride += p->data.getSize();
		return stride;
	}
	
	void Buffer::bindAttribs(ArrayRep<Attrib> ref) const	{
		bind(GL_ARRAY_BUFFER);
		const unsigned stride = getStride();
		for(unsigned i=0; i!=ref.getSize(); ++i)	{
			unsigned off = 0;
			const AtList *p = &mAttribs;
			for(; (p = p->next.get())!=0; off += p->data.getSize())	{
				if( strcmp(ref[i].name, p->data.name) )
					continue;
				assert( ref[i].type == p->data.type );
				assert( ref[i].num == p->data.num );
				glEnableVertexAttribArray(i);
				glVertexAttribPointer(i, p->data.num, p->data.type,
					p->data.normalize, stride, (void*)off );
				break;
			}
			assert(p && "attrib not found in a mesh!");
		}
	};
	
	void Buffer::unbindAttribs(unsigned num) const	{
		for(unsigned i=0; i!=num; ++i)
			glDisableVertexAttribArray(i);
	}
	
	
	//		MESH		//
	
	unsigned Mesh::GetPatchSize(int type)	{
		switch(type)	{
			case GL_TRIANGLES:
				return 3;
			case GL_TRIANGLE_STRIP:
			case GL_TRIANGLE_FAN:
				return 1;
			default:
				return 0;
		}
	}
	
	Mesh::Mesh():
	patchType(GL_TRIANGLES)
	{}

	Mesh::Mesh(const Mesh &m):
	patchType(m.patchType), off(m.off), num(m.num),
	pData(m.pData), pIndex(m.pIndex),
	pNode(m.pNode), pMaterial(m.pMaterial), pShader(m.pShader)
	{}

	Mesh::~Mesh()
	{}
	
	void Mesh::setup(int type, int o, int n)	{
		patchType = type;
		off = o; num = n;
	}

	void Mesh::draw() const	{
		//draw
		if( pIndex.get() )	{
			pIndex->bind( GL_ELEMENT_ARRAY_BUFFER );
			glDrawElements( patchType, num, GL_UNSIGNED_SHORT, (void*)off );
			Buffer::Unbind( GL_ELEMENT_ARRAY_BUFFER );
		}else	{
			glDrawArrays(patchType, off, num);
		}
		//check state
		const GLenum err = glGetError();
		assert(err == GL_NONE);
	}

	void Mesh::drawFull() const	{
		if( !pShader || !pData )
			return;
		Core::Inst()->mParams->mod.accept(pNode);
		Core::Inst()->mParams->mat.accept(pMaterial);
		pShader->use();
		pData->bindAttribs( pShader->getAttribs() );
		draw();
		pData->unbindAttribs( pShader->getAttribs().getSize() );
	}
	
}