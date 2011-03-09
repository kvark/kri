//
//  asset.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_ASSET_H
#define	KRI_ASSET_H

#include "pointer.h"

struct Lib3dsMesh;

namespace kri	{
	class Scene;
	class Mesh;
	namespace ren	{
		class Texture;
	}

namespace asset	{
	struct VertexData;
	
	template<typename T>
	class Loader	{
	public:
		Pointer<T> read(const char*);
		Loader()	{}
		~Loader()	{}
	};

	class Loader3Ds : public Loader<Scene>	{
		Pointer< Array<VertexData> > unroll_vertices(Lib3dsMesh*const) const;
		Pointer<Mesh> upload_data(ArrayRep<VertexData>) const;
		Pointer<Mesh> upload_data_squashed(ArrayRep<VertexData>) const;
		void normalize(Lib3dsMesh&) const;
	public:
		bool doSquash,doTransform;
		Pointer<ren::Texture> defColorTex;
		Loader3Ds();
		~Loader3Ds();
		Pointer<Scene> read(const char*);
	};

	class LoaderTGA : public Loader<ren::Texture>	{
	public:
		Pointer<ren::Texture> read(const char*);
	};


	typedef kri::Pointer< kri::Array<char> >	CharBuffer;

	class Manager : public kri::Reference	{
		char str[1024];
		const unsigned offset;
	public:
		Loader3Ds	loader3Ds;
		Manager(const char*);
		const char* modPath(const char*);
		CharBuffer read(const char*);
	};

}//asset
}//kri
#endif//KRI_ASSET_H