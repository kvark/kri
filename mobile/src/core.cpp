//
//  core.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "core.h"
#include "data.h"
#include "asset.h"

#include <assert.h>

namespace kri	{
	
	Core* Core::instance = 0;
	
	Core* Core::Inst(bool allowFail)	{
		assert(instance || allowFail);
		return instance;
	}
	
	Core::Core(const char* basePath)
	: mResMan(new asset::Manager(basePath))
	, mParams(new data::All())
	{
		assert(!instance);
		instance = this;
	}
	
	Core::~Core()	{
		assert(instance == this);
		instance = 0;
	}
	
}