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
};

struct Camera
{
    vec3 pos;
    vec3 dir;
    vec3 right;
    vec3 up;
};

struct Sphere
{
    Hittable hitData; 
    vec3 pos; 
    float radius;
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
    int type;

    vec3 pos; 
    vec3 n;
    vec3 color;


    float t; 
};

struct Ray
{
    vec3 pos;
    vec3 dir;
};

struct Sample
{
    vec3 color; 
    int hitCount; 
};




layout (location = 0) out vec4 color;
in vec2 uv;

#define MAX_BOUNCE 3
#define SPHERE_COUNT 3
#define TRIANGLE_COUNT 2

#define SPHERE 0
#define TRIANGLE 1

vec3 sun = vec3(-1, -1, 0);
        
vec3 WorldToCamera(Camera cam, vec3 worldPos);
vec3 RaySolve(Ray ray, float t);

HitData HitWorld(Sphere spheres[SPHERE_COUNT], Triangle triangles[TRIANGLE_COUNT], Camera cam, Ray r, HitData data, int bounceCounter, vec2 uv, bool shadowCheck);
float HitSphere(vec3 center, float radius, Ray ray);
float HitTriangle(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray);



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
    r.pos = cam.pos;
    r.dir = normalize(vec3(uvN.xy, 1.0f));

    
    Sphere sphereA; 
    sphereA.pos =  vec3(0, -0.3, 4);
    sphereA.radius = 1.5;

    Sphere sphereB; 
    sphereB.pos =  vec3(2.0, .5, 6);
    sphereB.radius = 1.5;

    Sphere sphereC; 
    sphereC.pos =  vec3(0.0, 1002.00, 0);
    sphereC.radius = 1000.0;


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


    Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT]
    (
        sphereA,
        sphereB,
        sphereC
    );
    
    Triangle triangles[TRIANGLE_COUNT] = Triangle[TRIANGLE_COUNT]
    (
        triA,
        triB
    );



    HitData data;
    data.color = vec3(0.1, 0.1, 0.1);
    data = HitWorld(spheres, triangles, cam, r, data, MAX_BOUNCE, uvN, true);

    color = vec4(data.color, 1.0); 
    


    //float t = -1.0f; 
    //
    //// Floor check 
    //t = max(
    //        HitTriangle(WorldToCamera(cam, triA.pos), WorldToCamera(cam, triA.vertA), WorldToCamera(cam, triA.vertB), WorldToCamera(cam, triA.vertC), r),
    //        HitTriangle(WorldToCamera(cam, triB.pos), WorldToCamera(cam, triB.vertA), WorldToCamera(cam, triB.vertB), WorldToCamera(cam, triB.vertC), r));

    // We can assume that the triangle's normal is (0, 1, 0) but
    // only this specific case 


};


// Get a color sample of the world 
HitData HitWorld(Sphere spheres[SPHERE_COUNT], Triangle triangles[TRIANGLE_COUNT], Camera cam, Ray r, HitData data, int bounceMax, vec2 uv, bool checkShadow)
{

    //vec3 worldAmbient = vec3

    data.color = vec3(1.0, 1.0, 1.0);
    int bounceCount = 1;

    vec3 startPos;
    vec3 startDir;

    bool hitSky = false; 

    for (int bounce = 0; bounce < MAX_BOUNCE; bounce++)
    {
        float t = -1.0; 
        int type = -1;

        bool hasItem = false; 

        //vec3 holdCol = mix(vec3(0.1, 0.4, 0.6), vec3(0.6, 0.4, 0.2), uv.y);
        vec3 holdCol = mix(vec3(1, 0, 0), vec3(0, 1, 0), uv.y);


        // Check world for best collision choice in spheres 
        for (int i = 0; i < spheres.length(); i++)
        {
            Sphere sphere = spheres[i];

            vec3 sphereLocal = WorldToCamera(cam, sphere.pos);

            float currCheckT = HitSphere(sphereLocal, sphere.radius, r);

            // If valid then generate normals and color 
            if(currCheckT > 0.0)
            {   
                if (hasItem && currCheckT > t)
                    continue; 

                

                
                hasItem = true; 

                t = currCheckT;
                vec3 n = normalize(RaySolve(r, t) - sphereLocal);
                
                data.pos = RaySolve(r, t);
                //holdCol = vec3(0.1, 0.8, 0);
                
                // Store first point of this cell 
                if (!hasItem)
                {
                    startPos = data.pos;
                    startDir = n;
                }
               
                
                holdCol = vec3(1,1,1);
                data.n = n;

                //r.pos = sphereLocal - (r.dir * sphere.radius);


                type = SPHERE;

                // Bounce
                //data = HitWorld(spheres, triangles, cam, r, 0);
            }
        }

    

        // Check world for best collision choice in triangles 
        //for (int i = 0; i < triangles.length(); i++)
        //{
        //    Triangle triangle = triangles[i];
        //
        //    float currCheckT = 
        //    HitTriangle(
        //        WorldToCamera(cam, triangle.pos), 
        //        WorldToCamera(cam, triangle.vertA), 
        //        WorldToCamera(cam, triangle.vertB), 
        //        WorldToCamera(cam, triangle.vertC), 
        //        r);
        //
        //    if(currCheckT > t)
        //    {
        //        t = currCheckT;
        //        vec3 n = vec3(0, 1, 0);
        //
        //        data.pos = RaySolve(r, t);
        //        data.color *= vec3(1,0,0);
        //        data.n = n;
        //
        //        type = TRIANGLE;
        //    }
        //
        //
        //
        //    // Ray to triangle position 
        //    // r.pos
        //}


        

       

        // Skybox sample
        data.color += holdCol;

        if (t <= 0.0)
        {
            //data.color *= 0; //vec3(0,0,0);
            //holdCol = vec3(0.1, 0.4, 0.6);
            bounceCount += 1;
            hitSky = true; 
            break;
        }
        else
        {
            // Valid hit was made 
            bounceCount += 1;

            r.pos = data.pos;
            r.dir = data.n;
        }

    }

   
    // NOTE: This system runs by choosing the first thing that gets hit
    //       in the arrays. This will need to change in the future but
    //       works for now 


    //if(checkShadow == true)
    //{
    //        // Check if illuminated by direct light 
    //    Ray shadowRay;
    //    shadowRay.pos = startPos; //data.pos;
    //    shadowRay.dir = sun;
    //    //
    //    HitData shadowData;
    //    
    //
    //    bool hasHit = false; 
    //    for (int i = 0; i < spheres.length(); i++)
    //    {
    //        
    //        Sphere sphere = spheres[i];
    //
    //        vec3 sphereLocal = WorldToCamera(cam, sphere.pos);
    //
    //        float currCheckT = HitSphere(sphereLocal, sphere.radius, shadowRay);
    //        
    //
    //        // Check if hit or light 
    //        if(currCheckT > 0.0)
    //        {   
    //            data.color = vec3(0,0,0);
    //
    //            // Valid hit 
    //            //hasHit = true;
    //            //break;
    //            //
    //        }
    //
    //    }
    //
    //    if(hasHit)
    //    {
    //        //data.color = vec3(0,0,0);
    //    }
    //}
    
    if (hitSky)
    {
        data.color *= 1.0 / (bounceCount);
    }
    else
    {
        data.color = vec3(0,0,0);
    }

    return data;
}



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
    return ray.pos + t * ray.dir;
} 

float HitSphere(vec3 center, float radius, Ray ray)
{
    // Source: https://raytracing.github.io/books/RayTracingInOneWeekend.html  

    vec3 oc = ray.pos - center; // Fixed direction
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

    vec3 orig = ray.pos;
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

vec3 RaySpherePos()
{
    return vec3(0,0,0);
}

vec3 RayTrianglePos()
{
    return vec3(0,0,0);
}

//vec3 random_unit_vector() {
//    while (true) {
//        auto p = vec3::random(-1,1);
//        auto lensq = p.length_squared();
//        if (lensq <= 1)
//            return p / sqrt(lensq);
//    }
//}