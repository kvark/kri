//
//  node.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-28.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_NODE_H
#define	KRI_NODE_H

#include "pointer.h"
#include <glm/core/type.hpp>

namespace kri	{
	typedef glm::mat4 Spatial;

	class Node : public Reference	{
		Spatial world;
		bool dirty;
	
	public:
		static const Spatial Identity;
		Node();
		~Node();
		
		Node *parent;
		Spatial local;
		glm::vec3 &pos;
		
		void touch()	{
			dirty = true;
		}
		const Spatial& getWorld();
	};
	
}//kri
#endif//KRI_NODE_H