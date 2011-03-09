//
//  asset.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "asset.h"
#include "core.h"
#include "material.h"
#include "mesh.h"
#include "node.h"
#include "render.h"
#include "scene.h"

#include "lib3ds.h"
#include <cmath>
#include <glm/core/type.hpp>
#include <glm/core/func_exponential.hpp>
#include <glm/core/func_geometric.hpp>
#include <glm/gtx/transform2.hpp>
#include <glm/gtx/inverse_transpose.hpp>

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <OpenGLES/ES2/gl.h>


namespace kri	{
namespace asset	{

	//		3DS LOADER		//

	static glm::mat4 makeSpatial(const float (&p)[3], const float (&t)[3], float roll)	{
		return glm::inverse( glm::lookAt( glm::vec3(p[0],p[1],p[2]), glm::vec3(t[0],t[1],t[2]), glm::vec3(0.f,0.f,1.f) ));
		const glm::vec3 pos(p[0],p[1],p[2]), dir(t[0]-p[0],t[1]-p[1],t[2]-p[2]);
		glm::vec3 zax = glm::normalize(dir), yax(0.f,1.f,0.f);
		if(!zax.x && !zax.y)
			yax = glm::normalize( glm::vec3(-zax.y,0.f,0.f) );
		glm::vec3 xax = glm::cross(yax,zax);
		yax = glm::cross(zax,xax);
		glm::mat4 mx(
			glm::vec4(xax,0.f), glm::vec4(yax,0.f),
			glm::vec4(zax,0.f), glm::vec4(pos,1.f) );
		//apply roll here
		return mx;
	}

	struct VertexData	{
		float pos[3];
		float nor[3];
		float tex[2];
	};
	typedef float vec3[3];

	class Comparator	{
	public:
		static const VertexData *base;
		
		static int faces(const void *p0, const void *p1)	{
			return (int)
				static_cast<const Lib3dsFace*>(p0)->material-
				static_cast<const Lib3dsFace*>(p1)->material;
		}
		
		static int verts(const void *p0, const void *p1)	{
			const int i0 = *static_cast<const unsigned short*>(p0);
			const int i1 = *static_cast<const unsigned short*>(p1);
			return memcmp( base+i0, base+i1, sizeof(VertexData) );
		}
	};

	const VertexData* Comparator::base = 0;


	static const Attrib vAttribs[] =	{
		{GL_FLOAT,	3,	false,	"at_pos"	},
		{GL_FLOAT,	3,	false,	"at_normal"	},
		{GL_FLOAT,	2,	false,	"at_tex0"	},
	};

	template<typename T>
	static void fill(const Array<T> &ar, int val=0)	{
		memset( ar.base, val, ar.size * sizeof(T) );
	}

	
	Loader3Ds::Loader3Ds(): doSquash(true),doTransform(true)	{
		defColorTex.alloc()->bind();
		const unsigned char data[] = {0xFF,0xFF,0xFF};
		ren::Texture::Init(1,1,24,data);
	}

	Loader3Ds::~Loader3Ds()
	{}
	

	Pointer< Array<VertexData> > Loader3Ds::unroll_vertices(Lib3dsMesh *const lm) const	{
		//read vertex data
		const Pointer< Array<VertexData> > pVertices = new Array<VertexData>(3*lm->nfaces);
		VertexData *const vd = pVertices->base;
		Array<vec3> aNormals( 3*lm->nfaces );
		fill(*pVertices);
		fill(aNormals);
		lib3ds_mesh_calculate_vertex_normals( lm, aNormals.base );
		for(int j=0; j<lm->nfaces; ++j)	{
			for(int k=0; k<3; ++k)	{
				const int vi = lm->faces[j].index[k];
				const int x = 3*j+k;
				memcpy(vd[x].pos, lm->vertices[vi],	3*sizeof(float));
				memcpy(vd[x].nor, &aNormals[x],		3*sizeof(float));
				memcpy(vd[x].tex, lm->texcos[vi],	2*sizeof(float));
			}
		}
		return pVertices;
	}

	Pointer<Mesh> Loader3Ds::upload_data(ArrayRep<VertexData> aVerts) const	{
		const Pointer<Mesh> pMesh = new Mesh();
		pMesh->setup( GL_TRIANGLES, 0, aVerts.getSize() );
		pMesh->pData = new Buffer();
		pMesh->pData->mAttribs.insert(vAttribs[0])->insert(vAttribs[1])->insert(vAttribs[2]);
		pMesh->pData->init(GL_ARRAY_BUFFER, aVerts);
		return pMesh;
	}

	Pointer<Mesh> Loader3Ds::upload_data_squashed(ArrayRep<VertexData> aVerts) const	{
		const Pointer<Mesh> pMesh = new Mesh();
		unsigned j,k;
		typedef unsigned short face3[3];
		//choose unique
		Comparator::base = &aVerts[0];
		Array<unsigned short> aTrans( aVerts.getSize() );
		for(j=0; j<aTrans.size; ++j)
			aTrans[j] = j;
		qsort( aTrans.base, aTrans.size, sizeof(aTrans[0]), Comparator::verts );
		Array<face3> aIndices( aTrans.size/3 );
		for(k=1,j=1; j<aTrans.size; ++j)	{	//calculate number
			const int cr = memcmp( &aVerts[aTrans[j]], &aVerts[aTrans[j-1]], sizeof(VertexData) );
			assert(cr>=0);
			k += cr;
		}
		Array<VertexData> aVertOpt(k);
		for(k=-1,j=0; j<aTrans.size; ++j)	{	//fill indices
			if(!j || memcmp( &aVerts[aTrans[j]], &aVerts[aTrans[j-1]], sizeof(VertexData) ))
				aVertOpt[++k] = aVerts[aTrans[j]];
			aIndices[0][aTrans[j]] = k;
		}
		//upload to GPU
		pMesh->setup( GL_TRIANGLES, 0, aVertOpt.size );
		pMesh->pData = new Buffer();
		pMesh->pIndex = new BufferBase();
		pMesh->pData->mAttribs.insert(vAttribs[0])->insert(vAttribs[1])->insert(vAttribs[2]);
		pMesh->pData->init<VertexData>(GL_ARRAY_BUFFER, aVertOpt);
		pMesh->pIndex->init<face3>(GL_ELEMENT_ARRAY_BUFFER, aIndices);
		return pMesh;
	}
	
	void Loader3Ds::normalize(Lib3dsMesh &lm) const	{
		if(!doTransform)
			return;
		const glm::mat4 trans = glm::inverse(*reinterpret_cast<glm::mat4*>( lm.matrix ));
		for(int i=0; i!=lm.nvertices; ++i)	{
			glm::vec4 pv(0.f,0.f,0.f,1.f);
			memcpy( &pv, lm.vertices[i], 3*sizeof(float) );
			const glm::vec4 pt = trans * pv;
			memcpy( lm.vertices[i], &pt, 3*sizeof(float) );
		}
	}


	Pointer<Scene> Loader3Ds::read(const char *path)	{
		Pointer<Scene> pScene;
		char pathBuf[100];
		strcpy(pathBuf,path);
		char *const lastSlash = strrchr(pathBuf,'/');
		const char* modPath = Core::Inst()->mResMan->modPath(path);
		Lib3dsFile *const f3d = lib3ds_file_open(modPath);
		if(!f3d)
			return pScene;
		int i;
		LoaderTGA loadTGA;
		pScene.alloc();
		for(i=0; i<f3d->nmaterials; ++i)	{
			Pointer<Material> pMat = new Material();
			pScene->mMaterials.insert(pMat);
			const Lib3dsMaterial &m = *f3d->materials[i];
			pMat->diffuse	= glm::vec4( m.diffuse[0], m.diffuse[1], m.diffuse[2], 1.f );
			pMat->specular	= glm::vec4( m.specular[0],m.specular[1],m.specular[2],1.f );
			pMat->glossiness = 100.f * m.shininess;
			if( m.texture1_map.name[0] )	{
				strcpy((lastSlash ? lastSlash+1 : pathBuf), m.texture1_map.name );
				pMat->pTexture = loadTGA.read(pathBuf);
			}
			if(! pMat->pTexture )
				pMat->pTexture = defColorTex;
		}
		for(i=0; i<f3d->nmeshes; ++i)	{
			Lib3dsMesh *const lm = f3d->meshes[i];
			normalize(*lm);
			qsort( lm->faces, lm->nfaces, sizeof(Lib3dsFace), Comparator::faces );
			const Pointer< Array<VertexData> > pUnrolled = unroll_vertices(lm);
			Pointer<Mesh> pMesh, pOrig = (doSquash ?
				upload_data_squashed(*pUnrolled) : upload_data(*pUnrolled));
			if(doTransform)
				pOrig->pNode.alloc()->local = *reinterpret_cast<glm::mat4*>( lm->matrix );
			//read face data
			int j, prev = -1,start=0;
			for(j=0; j<lm->nfaces; ++j)	{
				const int cur = lm->faces[j].material;
				if(cur == prev) continue;
				if( pMesh.get() )
					pMesh->setup(GL_TRIANGLES,3*start,3*j);
				List< Pointer<Material> > *pl = &pScene->mMaterials;
				for(int counter=cur; pl && --counter>=0; pl=pl->next.get());
				assert(pl);
				pMesh = new Mesh(*pOrig);
				pScene->mMeshes.insert(pMesh);
				pMesh->pMaterial = pl->data;
				start=j; prev=cur;
			}
			if(pMesh.get())
				pMesh->setup(GL_TRIANGLES,3*start,3*j);
		}
		for(i=0; i<f3d->ncameras; ++i)	{
			Pointer<Camera> pCam = new Camera();
			pScene->mCameras.insert(pCam);
			const Lib3dsCamera &cam = *f3d->cameras[i];
			pCam->near = cam.near_range;
			if(pCam->near < 0.01f)	{
				//invalid near plane value!
				pCam->near = 1.f;
			}
			pCam->far = cam.far_range;
			pCam->fov = cam.fov;
			const Pointer<Node> &pn = pCam->pNode = new Node();
			pn->local = makeSpatial( cam.position, cam.target, cam.roll );
		}
		for(i=0; i<f3d->nlights; ++i)	{
			Pointer<Light> pLit = new Light();
			pScene->mLights.insert(pLit);
			const Lib3dsLight &lit = *f3d->lights[i];
			pLit->near = lit.inner_range;
			pLit->far = lit.outer_range;
			pLit->fov = lit.falloff;
			pLit->hotspot = lit.hotspot / lit.falloff;
			pLit->attenuation = lit.attenuation;
			pLit->color = lit.multiplier * glm::vec4( lit.color[0], lit.color[1], lit.color[2], 1.f );
			const Pointer<Node> &pn = pLit->pNode = new Node();
			pn->local = makeSpatial( lit.position, lit.target, lit.roll );
		}

 		return pScene;
	}
	
	
	//		TGA LOADER	//

	struct HeadTGA	{
		unsigned char	idSize;
		unsigned char	cmType,imType;
		unsigned short	cmStart,cmLen;
		unsigned char	cmBits;
		unsigned short	xrig,yrig;
		unsigned short	wid,het;
		unsigned char	bits,descr;
		//methods
		bool check() const	{
			if(cmType!=0 || imType!=2)
				return false;
			if(xrig+yrig)
				return false;
			if(descr<bits && bits!=24+descr)
				return false;
			return true;
		}
		bool read(FILE *const fi)	{
			fread(&idSize,1,1,fi);
			fread(&cmType,1,2,fi);
			fread(&cmStart,2,2,fi);
			fread(&cmBits,1,1,fi);
			fread(&xrig,2,2,fi);
			fread(&wid,2,2,fi);
			fread(&bits,1,2,fi);
			assert(ftell(fi) == 18);
			return check();
		}
	};

	Pointer<ren::Texture>	LoaderTGA::read(const char *path)	{
		Pointer<ren::Texture> pTexture;
		const char* modPath = Core::Inst()->mResMan->modPath(path);
		FILE *const fi = fopen( modPath, "rb" );
		if(!fi)
			return pTexture;
		HeadTGA head;
		if(! head.read(fi) )
			return pTexture;
		Array<char> buf( head.wid * head.het * (head.bits>>3) );
		fread(buf.base, 1, buf.size, fi);
		fclose(fi);
		for(unsigned i=0; i!=buf.size; i += (head.bits>>3))	{
			const char x = buf.base[i];
			buf.base[i] = buf.base[i+2];
			buf.base[i+2] = x;
		}
		pTexture.alloc()->bind();
		ren::Texture::Init( head.wid, head.het, head.bits, buf.base );
		return pTexture;
	}

	
	//		RESOURCE MANAGER	//

	Manager::Manager(const char* path):
	offset(static_cast<unsigned>( strlen(path) ))	{
		assert(offset < sizeof(str));
		memcpy(str,path,offset);
		str[offset] = 0;
	}
	
	const char* Manager::modPath(const char* path)	{
		assert(strlen(path)+offset < sizeof(str));
		strcpy(str+offset,path);
		return str;
	}
	
	CharBuffer Manager::read(const char* path)	{
		FILE *const fi = fopen( modPath(path), "rb" );
		if(!fi)
			return CharBuffer();
		fseek(fi,0,SEEK_END);
		const int len = ftell(fi);
		fseek(fi,0,SEEK_SET);
		CharBuffer text = new Array<char>(len+1);
		fread( text->base, len,1,fi );
		text->base[len] = '\0';
		fclose(fi);
		return text;
	}

}//asset
}//kri