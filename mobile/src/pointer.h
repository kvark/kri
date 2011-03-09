//
//  pointer.h
//  test_long
//
//  Created by Dart Veider on 10-11-21.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_POINTER_H
#define	KRI_POINTER_H

#include <assert.h>

namespace kri	{
	
	//	Referenced object	//

	template<class>
	class Pointer;
	
	class Reference	{
		unsigned mUsed;
		template<class>
		friend class Pointer;
	protected:
		Reference(): mUsed(0)	{}
		virtual ~Reference()	{}
	};
	
	
	//	Referenced array	//
	
	template<class T>
	class Array : public Reference	{
		void operator=(const Array&);
		Array(const Array&);
	public:
		const unsigned size;
		T *const base;
		//methods
		Array(unsigned num)
		: size(num), base(new T[num])
		{}
		Array(const T* ptr, unsigned num)
		: size(num), base(new T[size])	{
			for(unsigned i=0; i!=size; ++i)
				base[i] = ptr[i];
		}
		~Array()	{
			delete[] base;
		}
		T& operator[](unsigned id)	{
			assert(id<size);
			return base[id];
		}
	};
	
	template<class T>
	class ArrayRep	{
		unsigned size;
		const T* base;
	public:
		ArrayRep()
		: size(0),base(0)
		{}
		ArrayRep(const Array<T> &ar)
		: size(ar.size), base(ar.base)
		{}
		~ArrayRep()
		{}
		const T& operator[](unsigned id) const 	{
			assert(id<size);
			return base[id];
		}
		unsigned getSize() const	{
			return size;
		}
	};

	
	//	Smart pointer	//
	
	template<class T>
	class Pointer	{
		T*	mPointer;
	public:
		Pointer(): mPointer(0)	{}
		Pointer(T *const ptr): mPointer(0)	{
			*this = ptr;
		}
		Pointer(const Pointer& ptr): mPointer(0)	{
			*this = ptr;
		}
		~Pointer()	{
			reset();
		}
		Pointer& alloc()	{
			*this = new T();
			return *this;
		}
		void reset()	{
			if(!mPointer) return;
			assert( mPointer->mUsed > 0 );
			if(!-- (mPointer->mUsed) )
				delete mPointer;
			mPointer = 0;
		}
		T* get() const	{
			return mPointer;
		}
		T* operator=(T *const ptr)	{
			if(ptr != mPointer)	{
				if(ptr)
					++(ptr->mUsed);
				reset();
				mPointer = ptr;
			}
			return ptr;
		}
		Pointer& operator=(const Pointer &ptr)	{
			*this = ptr.get();
			return *this;
		}
		T* operator->() const	{
			return mPointer;
		}
		T& operator*()	{
			return *mPointer;
		}
		const T& operator*() const	{
			return *mPointer;
		}
		operator bool() const {
			return mPointer != 0;
		}
	};
	

	//	Linked list element		//

	template<typename T>	
	struct List : public Reference	{
		//typedef typename List Type;
		Pointer<List> next;
		T data;
		List()	{}
		List(const T& elem): data(elem)	{}
		void clear()	{
			next.reset();
		}
		Pointer<List>& insert(const T&elem)	{
			Pointer<List> old = next;
			next = new List(elem);
			next->next = old;
			return next;
		}
		Pointer<List>& append()	{
			next = new List();
			return next;
		}
		List& operator=(const List& lis)	{
			if(lis.next)	{
				next = new List( lis.next->data );
				*next = *lis.next;
			}else next.reset();
			return *this;
		}
	};

}//kri
#endif//KRI_POINTER_H
