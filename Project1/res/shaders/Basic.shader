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
       

struct Camera
{
    vec3 pos;
    vec3 dir;
    vec3 right;
    vec3 up;
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

struct Ray
{
    vec3 origin;
    vec3 dir;
};

vec3 RaySolve(Ray ray, float t)
{
    return ray.origin + t * ray.dir;
} 

float HitSphere(vec3 center, float radius, Ray ray)
{
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


layout (location = 0) out vec4 color;
in vec2 uv;
        

void main()
{
    vec2 uvN = 2.0 * uv - 1.0;
    uvN = vec2(uvN.x, uvN.y * 480.0f / 640.0f);

   

    Camera cam; 
    cam.pos =   vec3( 1,  -3,  0);
    cam.dir =   vec3( 0,  0.1, -1);
    cam.right = vec3( 1,  0,  0);
    cam.up =    cross(cam.right, cam.dir);

    Ray r;
    r.origin = cam.pos;
    r.dir = normalize(vec3(uvN.xy, 1.0f));

    
    vec3 spherePos = vec3(0, 0, -6);
    vec3 sphereLocal = WorldToCamera(cam, spherePos);
    float sphereRadius = 1.5;


    vec3 col = vec3(1.0, 1.0, 1.0);

    float t = HitSphere(sphereLocal, sphereRadius, r);
    if (t > 0.0)
    {
        vec3 n = normalize(RaySolve(r, t) - sphereLocal);
        color = vec4(n, 1.0);
        //color = vec4( 0.5 * col * (n.x + 1, n.y + 1, n.z + 1), 1.0);
    }
    else
    {
        color = vec4(1.0, 1.0, 1.0, 1.0); 
    }
};