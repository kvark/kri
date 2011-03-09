//
//  data.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_DATA_H
#define	KRI_DATA_H

#include "pointer.h"
#include <glm/core/type.hpp>

namespace kri	{
	namespace shade	{
		struct Unidata;
	}
	namespace ren	{
		class Texture;
	}
	class Camera;
	class Light;
	class Material;
	class Node;

	namespace data	{

		class Model	{
		public:
			glm::mat4	model;
			void accept(const Pointer<kri::Node>&);
		};
		
		class Camera	{
		public:
			glm::mat4	projection;
			glm::vec4	pos,dir;
			void accept(const Pointer<kri::Camera>&);
		};

		class Material	{
		public:
			glm::vec4	emissive, diffuse, specular;
			Pointer<ren::Texture>	pTexture;
			float	glossiness;
			void accept(const Pointer<kri::Material>&);
		};

		class Light	{
		public:
			glm::vec4	color, pos, dir;
			glm::mat4	projection;
			void accept(const Pointer<kri::Light>&);
		};
		
		class All : public Reference	{
			Pointer< Array<shade::Unidata> > dict;
		public:
			Model		mod;
			Camera		cam;
			Material	mat;
			Light		lit[4];
			All();
			~All();
			const ArrayRep<shade::Unidata> getBook() const;
		};

	}
}//kri
#endif//KRI_DATA_H