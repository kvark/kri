//
//  shader.h
//  test_long
//
//  Created by Dart Veider on 10-11-16.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_SHADER_H
#define	KRI_SHADER_H

#include "pointer.h"

namespace kri	{
	struct Attrib;
	
namespace shade	{
	
	class Program;
	
	class Object : public kri::Reference	{
		const unsigned mHardId;
		friend class Program;
	public:
		static kri::Pointer<Object> Load(const char*);
		Object(unsigned);
		~Object();
		bool compile(const char*);
		bool isCompiled() const;
	};
	
	class Program : public kri::Reference	{
		const unsigned mHardId;
		int mStamp;
	public:
		static const Program& Default; 
		Program();
		~Program();
		void attach(const Object&);
		void setInput(const char*const[]);
		bool link();
        bool fill(const char*const[]);
		void bind() const;
		int getUniform(const char*);
		bool isLinked() const;
		int getStamp() const		{ return mStamp; }
		unsigned getHardId() const	{ return mHardId; }
	};

	struct Unidata	{
		int type,num;
		char name[32];
		const void *data;
	};
	typedef ArrayRep<Unidata>	Unidict;

	struct Uniform : public Unidata	{
	public:
		int loc;
		void push(unsigned&) const;
		void deriveType(int glType, int glSize);
	};

	class Bundle : public Reference	{
		int	mProgStamp;
		List<Uniform>	mUniforms;
		Pointer< Array<Attrib> >	mAttribs;
		void linkData(Uniform&);
	public:
		const Pointer<Program>	mProgram;
		List<Unidict>	mDictionaries;
		//construct
		Bundle();
		Bundle(const Bundle&);
		~Bundle();
		//operate
		void use();
		void sync();
		const List<Uniform>	getUniforms()	const;
		ArrayRep<Attrib>	getAttribs()	const;
	};
	
}//shade
}//kri
#endif//KRI_SHADER_H