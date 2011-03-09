//
//  scene.h
//  test_long
//
//  Created by Dart Veider on 10-12-02.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef	KRI_SCENE_H
#define	KRI_SCENE_H

#include "pointer.h"
#include <glm/core/type.hpp>


namespace kri	{
	class Mesh;
	class Material;
	class Node;

	class Projector : public Reference	{
		glm::mat4	matrix;
	public:
		enum Type	{
			PERSPECTIVE, ORTHOGONAL, OMNI
		}type;
		float fov, aspect;	//=wid/het
		float near, far;
		Pointer<Node> pNode;
		//methods
		Projector();
		~Projector();
		const glm::mat4& getProjection();
	};
	
	class Camera : public Projector	{
	public:
		Camera();
		~Camera();
	};
	
	class Light : public Projector	{
	public:
		float hotspot;	//fraction of FOV
		float attenuation;
		glm::vec4	color;
		Light();
		~Light();
	};
	
	
	typedef Pointer<Mesh>		PMesh;
	typedef Pointer<Material>	PMaterial;
	typedef Pointer<Camera>		PCamera;
	typedef Pointer<Light>		PLight;


	class Scene : public Reference	{
	public:
		Scene();
		~Scene();
		List<PMesh>		mMeshes;
		List<PMaterial>	mMaterials;
		List<PCamera>	mCameras;
		List<PLight>	mLights;
	};

}//kri
#endif//KRI_SCENE_H