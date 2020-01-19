#include "sphere.h"

//constructor given  center, radius, and material
sphere::sphere(glm::vec3 c, float r, int m, scene* s) : rtObject(s)
{
	center = c;
	radius = r;
	matIndex = m;
	myScene = s;
}

float sphere::testIntersection(glm::vec3 eye, glm::vec3 dir)
{
	//see the book for a description of how to use the quadratic rule to solve
	//for the intersection(s) of a line and a sphere, implement it here and
	//return the minimum positive distance or 9999999 if none

	float a = glm::dot(dir, dir);
	float b = glm::dot(dir, (eye - center));
	float c = glm::dot((eye - center), (eye - center)) - pow(radius, 2);
	float root = glm::dot(-dir, (eye - center));
	float div = sqrt(pow(b, 2) - (a * c));

	float t0 = (root - div) / a;
	float t1 = (root + div) / a;

	if (t0 > 0 && t1 > 0)
	{
		if (t0 < t1)
			return t0;
		else
			return t1;
	}

	return 9999999;
}

glm::vec3 sphere::getSurfacePoint(glm::vec3 eye, glm::vec3 dir)
{
	float distance = testIntersection(eye, dir);
	glm::vec3 surfaceP = eye + (distance * dir);

	glm::vec3 normal = surfaceP - center;
	surfaceP = surfaceP + 0.0001f * normal;

	return surfaceP;
}

glm::vec3 sphere::getNormal(glm::vec3 eye, glm::vec3 dir)
{
	//once you can test for intersection,
	//simply add (distance * view direction) to the eye location to get surface location,
	//then subtract the center location of the sphere to get the normal out from the sphere
	glm::vec3 normal;

	float distance = testIntersection(eye, dir);
	glm::vec3 surfaceP = eye + (distance * dir);

	normal = surfaceP - center;

	//dont forget to normalize
	normal = glm::normalize(normal);
	
	return normal;
}

glm::vec2 sphere::getTextureCoords(glm::vec3 eye, glm::vec3 dir)
{
	float pi = (atan(1) * 4);
	//find the normal as in getNormal
	glm::vec3 n = getNormal(eye, dir);
	//std::cout << std::endl << "n: " << glm::to_string(n);

	//use these to find spherical coordinates
	glm::vec3 x(1, 0, 0);
	glm::vec3 z(0, 0, 1);

	//phi is the angle down from z
	//theta is the angle from x curving toward y
	//hint: angle between two vectors is the acos() of the dot product

	//find phi using normal and z
	float phi = acos(glm::dot(n, z));

	//find the x-y projection of the normal
	glm::vec3 nXY(n.x, n.y, 0);

	//find theta using the x-y projection and x
	float theta = acos(glm::dot(nXY, x));

	//if x-y projection is in quadrant 3 or 4, then theta=2*PI-theta
	if (nXY.y < 0)
		theta = (2 * pi) - theta;

	//return coordinates scaled to be between 0 and 1
	glm::vec2 coords(phi / pi, theta / (2 * pi));
	coords = glm::clamp(coords, (float)0, (float)1);
	return coords;
}