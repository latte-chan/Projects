#include "triangle.h"

//constructor given  center, radius, and material
triangle::triangle(glm::vec3 p0, glm::vec3 p1, glm::vec3 p2, float tx0, float tx1, float tx2, float ty0, float ty1, float ty2, int m, scene* s) : rtObject(s)
{
	point0 = p0;
	point1 = p1;
	point2 = p2;

	texX0 = tx0;
	texX1 = tx1;
	texX2 = tx2;
	texY0 = ty0;
	texY1 = ty1;
	texY2 = ty2;
	matIndex = m;
	myScene = s;
}

float triangle::testIntersection(glm::vec3 eye, glm::vec3 dir)
{
	//see the book/slides for a description of how to use Cramer's rule to solve
	//for the intersection(s) of a line and a plane, implement it here and
	//return the minimum distance (if barycentric coordinates indicate it hit
	//the triangle) otherwise 9999999
	glm::vec3 bary1 = point1 - point0;
	glm::vec3 bary2 = point2 - point0;

	glm::mat3 matrix(bary1, bary2, -dir);
	glm::vec3 ans(eye.x - point0.x, eye.y - point0.y, eye.z - point0.z);
	glm::mat3 dB = { ans, matrix[1], matrix[2] };
	glm::mat3 dY = { matrix[0], ans, matrix[2] };
	glm::mat3 dT = { matrix[0], matrix[1], ans };


	float det = glm::determinant(matrix);
	float detB = glm::determinant(dB);
	float detY = glm::determinant(dY);
	float detT = glm::determinant(dT);

	float b = detB / det;
	float y = detY / det;
	float t = detT / det;


	if (b > 0 && y > 0 && (b + y) < 1 && t > 0)
		return t;

	return 9999999;
}

glm::vec3 triangle::getSurfacePoint(glm::vec3 eye, glm::vec3 dir)
{
	float distance = testIntersection(eye, dir);
	glm::vec3 surfaceP = eye + (distance * dir);

	glm::vec3 normal = getNormal(eye, dir);
	surfaceP = surfaceP + 0.0001f * normal;

	return surfaceP;
}

glm::vec3 triangle::getNormal(glm::vec3 eye, glm::vec3 dir)
{
	//construct the barycentric coordinates for the plane
	glm::vec3 bary1 = point1 - point0;
	glm::vec3 bary2 = point2 - point0;

	//cross them to get the normal to the plane
	//note that the normal points in the direction given by right-hand rule
	//(this can be important for refraction to know whether you are entering or leaving a material)
	glm::vec3 normal = glm::normalize(glm::cross(bary1, bary2));
	return normal;
}

glm::vec2 triangle::getTextureCoords(glm::vec3 eye, glm::vec3 dir)
{
	//find alpha and beta (parametric distance along barycentric coordinates)
	//use these in combination with the known texture surface location of the vertices
	//to find the texture surface location of the point you are seeing
	glm::vec3 baryCoords = getBarycentricCoords(eye, dir);
	float b = baryCoords.x;
	float y = baryCoords.y;

	glm::vec2 texP0 = glm::vec2(texX0, texY0);
	glm::vec2 texP1 = glm::vec2(texX1, texY1);
	glm::vec2 texP2 = glm::vec2(texX2, texY2);
	glm::vec2 texBary1 = texP1 - texP0;
	glm::vec2 texBary2 = texP2 - texP0;

	glm::vec2 texCoords = texP0 + (b * texBary1) + (y * texBary2);
	return texCoords;
}

glm::vec3 triangle::getBarycentricCoords(glm::vec3 eye, glm::vec3 dir)
{
	glm::vec3 bary1 = point1 - point0;
	glm::vec3 bary2 = point2 - point0;

	glm::mat3 matrix(bary1, bary2, -dir);
	glm::vec3 ans(eye.x - point0.x, eye.y - point0.y, eye.z - point0.z);
	glm::mat3 dB = { ans, matrix[1], matrix[2] };
	glm::mat3 dY = { matrix[0], ans, matrix[2] };
	glm::mat3 dT = { matrix[0], matrix[1], ans };


	float det = glm::determinant(matrix);
	float detB = glm::determinant(dB);
	float detY = glm::determinant(dY);
	float detT = glm::determinant(dT);

	float b = detB / det;
	float y = detY / det;
	float t = detT / det;

	return glm::vec3(b, y, t);
}