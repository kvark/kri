//
//  core.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_CORE_H
#define	KRI_CORE_H

#include "pointer.h"

namespace kri	{
	
	namespace asset	{
		class Manager;
	}
	namespace data	{
		class All;
	}
	
	class Core	{
		static Core*	instance;
	public:
		static Core* Inst(bool =false);
		Core(const char*);
		~Core();
		const Pointer<asset::Manager>	mResMan;
		const Pointer<data::All>		mParams;
	};
	
}//kri
#endif//KRI_CORE_H