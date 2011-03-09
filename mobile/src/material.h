//
//  material.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-28.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_MATERIAL_H
#define	KRI_MATERIAL_H

#include "pointer.h"
#include <glm/core/type.hpp>

namespace kri	{
	namespace ren	{
		class Texture;
	}

	class Material : public Reference	{
	public:
		glm::vec4 emissive, diffuse, specular;
		float glossiness;
		Pointer<ren::Texture>	pTexture;
		//methods
		Material();
		~Material();
	};
	
}//kri
#endif//KRI_MATERIAL_H