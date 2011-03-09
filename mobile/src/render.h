//
//  render.h
//  test_3ds
//
//  Created by Dart Veider on 10-11-22.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_RENDER_H
#define	KRI_RENDER_H

#include "pointer.h"

namespace kri	{
namespace ren	{

	class Surface : public Reference	{
	public:
		int wid,het,samples;
		int format;
		//methods
		Surface();
		~Surface();
		virtual void bindTo(int) const = 0;
	};
	typedef Pointer<Surface> PSurface;

	class Frame : public Reference	{
		const unsigned mHardId;
	public:
		static const Frame& Default;
		Frame();
		~Frame();
		void bind() const;
	};

	struct Container	{
		enum { NUM_COLORS=8 };
		PSurface	pStencil;
		PSurface	pDepth;
		PSurface	pColor[NUM_COLORS];
	};

	class Target : public Frame, public Container	{
		void addSurface(int, PSurface&, const PSurface&) const;
		Container	state;
	public:
		Target();
		~Target();
		void use(int);
	};

	class Buffer : public Surface	{
		const unsigned mHardId;
	public:
		static const Buffer& Default;
		Buffer();
		~Buffer();
		void bind() const;
		virtual void bindTo(int) const;
		unsigned getId() const	{ return mHardId; }
	};

	class Texture : public Surface	{
		const unsigned mHardId;
	public:
		static const Texture& Default; 
		static void Channel(unsigned);
		static void Init(unsigned,unsigned,int,const void*);
		Texture();
		~Texture();
		void bind() const;
		virtual void bindTo(int) const;
	};

}//ren
}//kri
#endif//KRI_ASSET_H