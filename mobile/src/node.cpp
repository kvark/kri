//
//  node.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-28.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "node.h"

namespace kri	{

	const Spatial Node::Identity = Spatial(1.f);

	Node::Node():
	parent(0), dirty(true),
	world(1.f), local(1.f),
	pos( *reinterpret_cast<glm::vec3*>(&world[3]) )
	{}

	Node::~Node()
	{}

	const Spatial& Node::getWorld()	{
		if(!this)
			return Identity;
		if(!parent)
			return local;
		if(!dirty)
			return world;
		world = parent->getWorld() * local;
		dirty = false;
		return world;
	}

}