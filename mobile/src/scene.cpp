//
//  scene.cpp
//  test_3ds
//
//  Created by Dart Veider on 10-11-28.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#include "material.h"
#include "mesh.h"
#include "node.h"
#include "scene.h"

#include <glm/gtc/matrix_projection.hpp>


namespace kri	{
	
	Projector::Projector()
	: fov(60.f),aspect(1.f)
	, near(1.f),far(100.f)
	{}
	
	Projector::~Projector()
	{}
	
	const glm::mat4& Projector::getProjection()	{
		matrix = glm::perspective(fov,aspect,near,far);
		return matrix;
	}


	Camera::Camera()
	{}
	Camera::~Camera()
	{}
	
	Light::Light()
	{}
	Light::~Light()
	{}
	
	Scene::Scene()
	{}
	Scene::~Scene()
	{}

}