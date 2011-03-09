//
//  mesh.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-24.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_MESH_H
#define	KRI_MESH_H

#include "pointer.h"

namespace kri	{
	
	class BufferBase : public Reference	{
		static unsigned GenerateId();
		const unsigned mHardId;
	public:
		//data
		static const BufferBase& Zero;
		//methods
		BufferBase();
		~BufferBase();
		void bind(int) const;
		static void Unbind(int);
		void init(int,const void *const,unsigned);
		template<typename T>
		void init(int target, const ArrayRep<T> &ar)	{
			init( target, &ar[0], ar.getSize() * sizeof(T) );
		}
	};
	
	
	struct Attrib	{
		//data
		int type;
		int num;
		bool normalize;
		char name[32];
		//methods
		static unsigned GetTypeSize(int);
		unsigned getSize() const;
		void translate(int);
	};
	typedef List<Attrib> AtList;
	
	class Buffer : public BufferBase	{
	public:
		//data
		AtList mAttribs;
		//methods
		Buffer();
		unsigned getStride() const;
		void bindAttribs(ArrayRep<Attrib>) const;
		void unbindAttribs(unsigned) const;
	};
	

	class Node;
	class Material;
	namespace shade	{
		class Bundle;
	}
	
	class Mesh : public Reference	{
		static unsigned GetPatchSize(int);
	public:
		//data
		Pointer<Buffer>			pData;
		Pointer<BufferBase>		pIndex;
		int patchType;
		int off,num;
		Pointer<Node>			pNode;
		Pointer<Material>		pMaterial;
		Pointer<shade::Bundle>	pShader;
		//methods
		Mesh();
		Mesh(const Mesh&);
		~Mesh();
		void draw() const;
		void drawFull() const;
		void setup(int,int,int);
	};

}//kri
#endif//KRI_MESH_H