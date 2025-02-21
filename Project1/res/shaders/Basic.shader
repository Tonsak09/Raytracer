#shader vertex
#version 330 core
        
layout (location = 0) in vec4 position;
out vec2 uv;
        

void main()
{
    gl_Position = vec4(position.xy, 0.0, 1.0);
    uv = position.zw;
};




#shader fragment
#version 330 core
       
struct Hittable 
{
    int type;
    int offset; 
}

struct Camera
{
    vec3 pos;
    vec3 dir;
    vec3 right;
    vec3 up;
};

struct Triangle
{
    vec3 pos;
    vec3 vertA;
    vec3 vertB;
    vec3 vertC;
};

struct HitData
{
    vec3 pos; 
    vec3 n;
    float t; 
};

struct Ray
{
    vec3 origin;
    vec3 dir;
};




layout (location = 0) out vec4 color;
in vec2 uv;
        
vec3 WorldToCamera(Camera cam, vec3 worldPos);
vec3 RaySolve(Ray ray, float t);
float HitSphere(vec3 center, float radius, Ray ray);
float HitTriangle(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray);

#define MAX_BOUNCE 3

void main()
{
    vec2 uvN = 2.0 * uv - 1.0;
    uvN = vec2(uvN.x, -uvN.y * 480.0f / 640.0f);


    Camera cam; 
    cam.pos =   vec3( 0, 0.3, -1);
    cam.dir =   normalize(vec3( 0,  -0.1,  1));
    cam.right = vec3( 1,  0,  0);
    cam.up =    cross(cam.right, cam.dir);

    Ray r;
    r.origin = cam.pos;
    r.dir = normalize(vec3(uvN.xy, 1.0f));

    
    vec3 spherePos = vec3(0, 0, 6);
    vec3 sphereLocal = WorldToCamera(cam, spherePos);
    float sphereRadius = 1.5;

    Triangle triA;
    triA.pos = vec3(0, 0, 0);
    triA.vertA = vec3(-0.5, 0.0, -0.5);
    triA.vertB = vec3(-0.5, 0.0,  0.5);
    triA.vertC = vec3( 0.5, 0.0, -0.5);

    Triangle triB;
    triB.pos = vec3(0, 0, 0);
    triB.vertA = vec3( 0.5, 0.0, -0.5);
    triB.vertB = vec3( 0.5, 0.0,  0.5);
    triB.vertC = vec3(-0.5, 0.0,  0.5);

    vec3 col = vec3(1.0, 1.0, 1.0);



    // Iterate through all of the scene hittables 
    //for (int i = 0; i < )
    


    float t = -1.0f; 
    
    // Floor check 
    t = max(
            HitTriangle(WorldToCamera(cam, triA.pos), WorldToCamera(cam, triA.vertA), WorldToCamera(cam, triA.vertB), WorldToCamera(cam, triA.vertC), r),
            HitTriangle(WorldToCamera(cam, triB.pos), WorldToCamera(cam, triB.vertA), WorldToCamera(cam, triB.vertB), WorldToCamera(cam, triB.vertC), r));

    // We can assume that the triangle's normal is (0, 1, 0) but
    // only this specific case 

    if (t > 0.0f)
    {
        // Reflect ray 
    }

    // Sphere check 
    t = max (t, HitSphere(sphereLocal, sphereRadius, r));


    if(t > 0.0f) // RayIntersectTri(trianglePos, vertA, vertB, vertC, r)
    {
        vec3 n = normalize(RaySolve(r, t) - sphereLocal);
        color = vec4(abs(n), 1.0);
    }
    else
    {
        color = vec4(1.0, 1.0, 1.0, 1.0); 
    }

};




// Convert a global position to the camera's local space
vec3 WorldToCamera(Camera cam, vec3 worldPos)
{
    mat3 mat;
    mat[0] = cam.right; 
    mat[1] = cam.up ;
    mat[2] = cam.dir;

    return inverse(mat) * worldPos;

    //vec3 rel = worldPos - cam.pos;
    //return vec3(dot(worldPos, cam.right), dot(worldPos, cam.up), dot(worldPos, cam.dir));
}

vec3 RaySolve(Ray ray, float t)
{
    return ray.origin + t * ray.dir;
} 

float HitSphere(vec3 center, float radius, Ray ray)
{
    // Source: https://raytracing.github.io/books/RayTracingInOneWeekend.html  

    vec3 oc = ray.origin - center; // Fixed direction
    float a = dot(ray.dir, ray.dir);
    float b = 2.0 * dot(ray.dir, oc);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0 * a * c; 

    if (discriminant < 0)
    {
        return -1.0;
    }
    else
    {
        //return 1.0;
        return (-b - sqrt(discriminant)) / (2.0 * a); // Fixed quadratic formula
    }
}


float HitTriangle(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray)
{
    // Source: Fast, Minimum Storage Ray/Triangle Intersection 

    vec3 orig = ray.origin;
    vec3 dir = ray.dir;
    float t;

    vec3 vertA = center + vertAOffset;
    vec3 vertB = center + vertBOffset;
    vec3 vertC = center + vertCOffset;

    vec3 edgeA = vertB - vertA;
    vec3 edgeB = vertC - vertA;
    
    vec3 pVec = cross(dir, edgeB);
    float det = dot(edgeA, pVec);



    if (det > -0.0001 && det < 0.001)
    {
        return 0.0;
    }

    float invDet = 1.0 / det;
    vec3 tVec = orig - vertA;

    float u = dot(tVec, pVec) * invDet;
    if(u < 0.0 || u > 1.0)
    {
        return 0.0;
    }

    vec3 qVec = cross(tVec, edgeA);

    float v = dot(dir, qVec) * invDet;
    if(v < 0.0 || u + v > 1.0)
    {
        return 0.0;
    }

    t = dot(edgeB, qVec) * invDet;
    return 1.0; 
}