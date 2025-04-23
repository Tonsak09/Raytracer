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

#define MAX_BOUNCE 4
#define SPHERE_COUNT 2
#define TRIANGLE_COUNT 2

#define SPHERE 0
#define TRIANGLE 1

vec3 sun = vec3(-1, -1, 0);
        
vec3 WorldToCamera(Camera cam, vec3 worldPos);
vec3 RaySolve(Ray ray, float t);
vec2 TilingAndOffset(vec2 uv, vec2 tiling, vec2 offset);
vec3 TriplanarTex(
    vec3 world, vec3 normal,
    vec2 frontTiling,   vec2 frontOffset,
    vec2 sideTiling,    vec2 sideOffset,
    vec2 topTiling,     vec2 topOffset,
    float sharpness);
vec3 RayTrianglePos(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray, out bool valid);
float RayPlane(vec3 center, vec3 N, Ray ray);


HitData HitWorld(Sphere spheres[SPHERE_COUNT], Triangle triangles[TRIANGLE_COUNT], Camera cam, Ray r, HitData data, int bounceCounter, vec2 uv, bool shadowCheck);
float HitSphere(vec3 center, float radius, Ray ray, out vec3 p,  out vec3 n, out bool valid);
float HitTriangle(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray);
float Checkered(vec2 uv);
float Checkered_3D(vec3 pos);

float Random (vec2 st);
vec3 RandInUnitSphere();
vec3 RandUnitVector();
float DiffusePBR(vec3 normal, vec3 dirToLight);
vec3 LamberScatter(Ray ray, vec3 n, out bool valid);
bool NearZero(vec3 vec);
vec3 RandInUnitSphere();
vec3 RandUnitVector();
vec3 DielectricScatter(Ray ray, vec3 n, float ir, out bool valid);
float DielectricReflectance(float cosine, float ref_idx);
vec3 Refract(Ray ray, vec3 normal, float ir, out bool valid);
vec3 Refract(Ray ray, vec3 normal, float etai_over_etat, out bool valid);
vec3 GetSphereExitPoint(vec3 p, vec3 d, vec3 center, float radius);

void main()
{
    vec2 uvN = 2.0 * uv - 1.0;
    uvN = vec2(uvN.x, -uvN.y * 480.0f / 640.0f);


    Camera cam; 
    cam.pos =   vec3( 0, 0.3, -1);
    cam.dir =   normalize(vec3( 0,  0,  1));
    cam.right = vec3( 1,  0,  0);
    cam.up =    cross(cam.right, cam.dir);

    Ray r;
    r.pos = cam.pos;
    r.dir = normalize(vec3(uvN.xy, 1.0f));

    
    Sphere sphereA; 
    sphereA.pos =  vec3(0.1, -0.2,  0.01);
    sphereA.pos =  vec3(0.0, -0.2, -0.2);
    sphereA.radius = 0.2;

    Sphere sphereB; 
    sphereB.pos =  vec3(0.3, -0.25, 0.05);
    sphereB.radius = 0.2;

    Sphere sphereC; 
    sphereC.pos =  vec3(0.0, 1002.00, 0);
    sphereC.radius = 1000.0;


    Triangle triA;
    triA.pos = vec3(0, 0.0, 0);
    triA.vertA = vec3( 0.5, 0.0, -0.5);
    triA.vertB = vec3( 0.5, 0.0,  0.5);
    triA.vertC = vec3(-0.5, 0.0,  0.5);

    Triangle triB;
    triB.pos = vec3(0, 0.0, 0);
    triB.vertA = vec3(-0.5, 0.0, -0.5); 
    triB.vertB = vec3(-0.5, 0.0,  0.5); 
    triB.vertC = vec3( 0.5, 0.0, -0.5); 


    Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT]
    (
        sphereA,
        sphereB
        //sphereC
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
};


// Get a color sample of the world 
HitData HitWorld(Sphere spheres[SPHERE_COUNT], Triangle triangles[TRIANGLE_COUNT], Camera cam, Ray r, HitData data, int bounceMax, vec2 uv, bool checkShadow)
{

    //vec3 worldAmbient = vec3

    //data.color = mix(vec3(0.1, 0.4, 0.6), vec3(0.6, 0.1, 0.1), uv.y);
    data.color = vec3(0.8, 0.8, 0.8);
    int bounceCount = 0;


    bool hitSky = false; 

    bool dialectric = false; 


    for (int bounce = 0; bounce < MAX_BOUNCE; bounce++)
    {
        float t = -1.0; 

        bool hasItem = false; 

        //vec3 holdCol = mix(vec3(0.1, 0.4, 0.6), vec3(0.6, 0.4, 0.2), uv.y);
        vec3 holdCol = data.color; //mix(vec3(1, 0, 0), vec3(0, 1, 0), uv.y);

        bool frontFace = true; 
        float ir = 1.1;


        // Check world for best collision choice in spheres 
        for (int i = 0; i < spheres.length(); i++)
        {
            Sphere sphere = spheres[i];

            vec3 sphereLocal = WorldToCamera(cam, sphere.pos);

            bool validSphere = false; 

            vec3 currP;
            vec3 currN;
            float currCheckT = HitSphere(sphereLocal, sphere.radius, r, currP, currN, validSphere);

            // If valid then generate normals and color 
            //if(currCheckT > t)
            if(validSphere)
            {   
                // Chooses the first sphere atm 
                if (hasItem && currCheckT > t)
                    continue; 
                hasItem = true; 

                t = currCheckT;
                vec3 n = normalize(RaySolve(r, t) - sphereLocal);
                bool isValidScatter = false; 

                vec3 holdPos = r.pos;
                data.pos = RaySolve(r, t);

                // TODO: Remove the single case check 

                if (i == 1)
                {
                    data.n = n; // LamberScatter(r, n, isValidScatter);
                    holdCol = data.color * DiffusePBR(n, vec3(0, 1, 0));
                    dialectric = false;
                }
                else
                {
                    vec3 temp = DielectricScatter(r, n, ir, isValidScatter); 
                    data.n = temp;
                    //data.pos += temp * sphere.radius;

                    // Jump ray to outside of sphere 

                    //holdCol = temp;
                    holdCol = vec3(0.0, 0.0, 0.0);

                    // if(temp.x < 0 || temp.y < 0 || temp.z < 0)
                    // {
                    //     holdCol = vec3(1, 0, 0);
                    // }
                    // else
                    // {
                    //     holdCol = vec3(0, 1, 0);
                    // }
                    
                    


                    if (isValidScatter) //(temp.x < 0 || temp.y < 0 || temp.z < 0)
                    {
                        data.pos = GetSphereExitPoint(r.pos, temp, sphereLocal, sphere.radius) ;
                        data.pos += -n * 0.0001;
                        dialectric = true; 
                    }
                    else
                    {
                        dialectric = false;
                    }
                }
            }
        }

        for (int i = 0; i < triangles.length(); i++)
        {
            Triangle triangle = triangles[i];

            const vec3 n = vec3(0, 1, 0);
            float currCheckT = RayPlane(
                    WorldToCamera(cam, triangle.pos), 
                    n, r);

            bool valid = 0.0 <= 
            HitTriangle(
                WorldToCamera(cam, triangle.pos), 
                WorldToCamera(cam, triangle.vertA), 
                WorldToCamera(cam, triangle.vertB), 
                WorldToCamera(cam, triangle.vertC), 
                r);


            // Ensure triangle collision 
            if(!valid)
                continue;

            // Make sure there is a succesful intersection 
            if(currCheckT < 0.0)
                continue;

            // Only use if current is faster 
            if (currCheckT > t && hasItem)
                continue; 
            

            t = currCheckT; 

            bool isValidScatter = false; 

            data.pos = RaySolve(r, currCheckT) + vec3(0, 0.00001, 0);
            data.n = vec3(0, 1, 0); //LamberScatter(r, n, isValidScatter);

            holdCol = data.color * normalize(vec3(0.8, 0.8, 0.8) * Checkered_3D(data.pos));
            
            dialectric = false;
        }
        


        if(dialectric)
        {
            //bounceCount -= 1;
        }


        bounceCount += 1;
        data.color += holdCol;

        if (t < 0.0)
        {
            // Did not hit anything 
            hitSky = true;
            break;
        }
        else
        {
            // Valid hit was made 
            r.dir = normalize(data.n);
            r.pos = data.pos;
        }
    }

   
    // NOTE: This system runs by choosing the first thing that gets hit
    //       in the arrays. This will need to change in the future but
    //       works for now 
    

    vec3 skyColor = mix(vec3(0.1, 0.4, 0.6), vec3(0.6, 0.1, 0.1), uv.y);

   if (hitSky)
    {
        data.color += mix(vec3(0.1, 0.4, 0.6), vec3(0.6, 0.1, 0.1), r.dir.y) * 0.9;
        bounceCount += 1;
        data.color *= (1.0 / (bounceCount));
    }
    else
    {
        // Does not bounce to sky and counts as shadow 
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

    return  inverse(mat) * worldPos;

    //vec3 rel = worldPos - cam.pos;
    //return vec3(dot(worldPos, cam.right), dot(worldPos, cam.up), dot(worldPos, cam.dir));
}

vec3 RaySolve(Ray ray, float t)
{
    return ray.pos + t * ray.dir;
} 

vec2 TilingAndOffset(vec2 uv, vec2 tiling, vec2 offset)
{
    return uv * tiling + offset;
}

vec3 TriplanarTex(
    vec3 world, vec3 normal,
    vec2 frontTiling,   vec2 frontOffset,
    vec2 sideTiling,    vec2 sideOffset,
    vec2 topTiling,     vec2 topOffset,
    float sharpness)
{

    vec2 frontUV = TilingAndOffset(world.xy, frontTiling, frontOffset);
    vec2 sideUV = TilingAndOffset(world.zy, sideTiling, sideOffset);
    vec2 topUV = TilingAndOffset(world.xz, topTiling, topOffset);

    vec3 sharpNorm = vec3(pow(abs(normal.x), sharpness), pow(abs(normal.y), sharpness), pow(abs(normal.z), sharpness)); ; 
    sharpNorm = sharpNorm / (sharpNorm.x + sharpNorm.y + sharpNorm.z);


    frontUV *= sharpNorm.z;
    sideUV *= sharpNorm.x;
    topUV *= sharpNorm.y;

    vec3 front = vec3(1.0, 0.0, 0.0) * sharpNorm.z; //Checkered(frontUV);
    vec3 side =  vec3(0.0, 1.0, 0.0) * sharpNorm.x; //Checkered(sideUV);
    vec3 top =   vec3(0.0, 0.0, 1.0) * sharpNorm.y; //Checkered(topUV);


    // Sample targets based on UVs
    return front + side + top;
}

float HitSphere(vec3 center, float radius, Ray ray, out vec3 p, out vec3 n, out bool valid)
{
    float tMin = -1000;
    float tMax = 10000;


    vec3 oc = ray.pos - center;
	float a = dot(ray.dir, ray.dir);
	float b = dot(oc, ray.dir);
	float c = dot(oc, oc) - radius * radius;
	float discriminant = b * b - a * c;

	if (discriminant >= 0)
	{
		float t1 = (-b - sqrt(discriminant)) / a;
		float t2 = (-b + sqrt(discriminant)) / a;

		if ((tMin <= t1 && t1 < tMax) || (tMin <= t2 && t2 < tMax))
		{
            // Choose which solution
			float t = (tMin <= t1 && t1 < tMax) ? t1 : t2;
			vec3 point = RaySolve(ray, t);
			vec3 normal = (point - center) / radius;

            valid = true;

			//hitRecord = NewHitRecord(t, point, normal, sphere.MaterialIndex);
			return t;
		}
	}


    valid = false;
	return -1.0f;









    // Source: https://raytracing.github.io/books/RayTracingInOneWeekend.html  

    //vec3 oc = ray.pos - center; // Fixed direction
    //float a = dot(ray.dir, ray.dir);
    //float b = 2.0 * dot(ray.dir, oc);
    //float c = dot(oc, oc) - radius * radius;
    //float discriminant = b * b - 4.0 * a * c; 
    //
    //if (discriminant < 0)
    //{
    //    return -1.0;
    //}
    //else
    //{
    //    //return 1.0;
    //    return (-b - sqrt(discriminant)) / (2.0 * a); // Fixed quadratic formula
    //}
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
        return -1.0;
    }

    float invDet = 1.0 / det;
    vec3 tVec = orig - vertA;

    float u = dot(tVec, pVec) * invDet;
    if(u < 0.0 || u > 1.0)
    {
        return -1.0;
    }

    vec3 qVec = cross(tVec, edgeA);

    float v = dot(dir, qVec) * invDet;
    if(v < 0.0 || u + v > 1.0)
    {
        return -1.0;
    }

    t = dot(edgeB, qVec) * invDet;
    return 1.0; 
}


vec3 RayTrianglePos(vec3 center, vec3 vertAOffset, vec3 vertBOffset, vec3 vertCOffset, Ray ray, out bool valid)
{
    float epsilon = 0.1;

    vec3 edge1 = vertBOffset - vertAOffset;
    vec3 edge2 = vertCOffset - vertAOffset;
    vec3 ray_cross_e2 = cross(ray.dir, edge2);
    float det = dot(edge1, ray_cross_e2);

    if (det > -epsilon && det < epsilon)
    {
        valid = false;
        return vec3(0,0, -50000);    // This ray is parallel to this triangle.
    }

    float inv_det = 1.0 / det;
    vec3 s = ray.pos - vertAOffset;
    float u = inv_det * dot(s, ray_cross_e2);

    if ((u < 0 && abs(u) > epsilon) || (u > 1 && abs(u-1) > epsilon))
    {
        valid = false; 
        return vec3(0,0,-50000);
    }

    vec3 s_cross_e1 = cross(s, edge1);
    float v = inv_det * dot(ray.dir, s_cross_e1);

    if ((v < 0 && abs(v) > epsilon) || (u + v > 1 && abs(u + v - 1) > epsilon))
    {
        valid = false; 
        return vec3(0,0,-50000);
    }

    // At this stage we can compute t to find out where the intersection point is on the line.
    float t = inv_det * dot(edge2, s_cross_e1);

    if (t > epsilon) // ray intersection
    {
        valid = true;
        return  vec3(ray.pos + ray.dir * t);
    }
    else // This means that there is a line intersection but not a ray intersection.
    {
        valid = false; 
        return vec3(0,0,-50000);
    }
}


float RayPlane(vec3 center, vec3 N, Ray ray)
{
    float denom = dot(N, ray.dir);
    if (abs(denom) < 1e-6) {
        // Ray is parallel to the plane
        return -1.0;
    }
    float t = dot(center - ray.pos, N) / denom;
    return (t >= 0.0) ? t : -1.0; // Return -1.0 if the intersection is behind the ray
}


float Checkered(vec2 uv)
{
    // add different dimensions
    float chessboard = floor(uv.x) + floor(uv.y);
    // divide it by 2 and get the fractional part, resulting in a value of 0 for even and 0.5 for odd numbers.
    chessboard = fract(chessboard * 0.5);
    // multiply it by 2 to make odd values white instead of grey
    chessboard *= 2.0;
    return chessboard;
}

float Checkered_3D(vec3 pos)
{
    float scale = 0.1;

    //scale the position to adjust for shader input and floor the values so we have whole numbers
    vec3 adjustedWorldPos = floor(pos / scale);
    //add different dimensions
    float chessboard = adjustedWorldPos.x + adjustedWorldPos.y + adjustedWorldPos.z;
    //divide it by 2 and get the fractional part, resulting in a value of 0 for even and 0.5 for off numbers.
    chessboard = fract(chessboard * 0.5);
    //multiply it by 2 to make odd values white instead of grey
    chessboard *= 2;
    return chessboard;
}


float DiffusePBR(vec3 normal, vec3 dirToLight)
{
	return clamp(dot(normal, dirToLight), 0.0, 1.0);
}



vec3 DirLight(vec3 lightDir, vec3 lightColor, float lightIntensity, vec3 camPos, vec3 pos, vec3 normal, float roughness, float metalness, vec3 albedo, vec3 specColor)
{
	vec3 V = normalize(camPos - pos);
	

	//float specExponent = (1.0f - roughness) * MAX_SPECULAR_EXPONENT;
	vec3 R = reflect(normal, lightDir);

    float d = clamp(dot(normal, lightDir), 0, 1);
	vec3 diffuse = vec3(d, d, d);
	vec3 F;
	//vec3 spec = MicrofacetBRDF(normal, lightDir, V, roughness, specColor, F);

	// Calculate diffuse with energy conservation, including cutting diffuse for metals
	//vec3 balancedDiff = DiffuseEnergyConserve(diffuse, spec, metalness);
	// Combine the final diffuse and specular values for this light
	vec3 total = (albedo) * lightIntensity * lightColor;


	return total;
}


vec3 LamberScatter(Ray ray, vec3 n, out bool valid)
{
    valid = false; 

    vec3 randUnit = RandUnitVector();
    vec3 scatteredDirection = n + randUnit;

    if (NearZero(scatteredDirection))
        scatteredDirection = n;

    valid = true; 
    return scatteredDirection;
}

// Noise function from The Book of Shaders 
float Random (in vec2 st) 
{
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}


/// <summary>
/// Gets a random vector 3 that exists within 
/// a unit sphere 
/// </summary>
/// <returns></returns>
vec3 RandInUnitSphere()
{
	while (true)
	{
		vec3 vec = vec3(Random(vec2(-1.0, 1.0)), Random(vec2(-1.0, 1.0)), Random(vec2(-1.0, 1.0)));
		float squared = dot(vec, vec); // square the vector 

		if (squared < 1.0f)
			return vec;
	}
}

/// <summary>
/// Get a random normalized vector 
/// </summary>
/// <returns></returns>
vec3 RandUnitVector()
{
	return normalize(RandInUnitSphere());
}

bool NearZero(vec3 vec)
{
    return (abs(vec.x) <= 0.0001) && (abs(vec.y) <= 0.0001) && (abs(vec.z) <= 0.0001);
}



vec3 DielectricScatter(Ray ray, vec3 n, float ir, out bool valid)
{
    vec3 attenuation = vec3(1.0, 1.0, 1.0);
    bool front = dot(ray.dir, n) >= 0;
    float ri = front ? (1.0 / ir) : ir;

    vec3 unit_direction = (ray.dir);
    float cos_theta = min(dot(-unit_direction, n), 1.0);
    float sin_theta = sqrt(1.0 - cos_theta*cos_theta);
    
    bool cannot_refract = ri * sin_theta > 1.0;
    vec3 direction;
    bool holdValue;
    
    if (cannot_refract || DielectricReflectance(cos_theta, ri) > 0.1f)
    {
        direction = reflect(unit_direction, n);
        valid = false; 
    }
    else
    {
        direction = refract(unit_direction, n, ri);
        valid = true; 
    }
    
    //valid = true; 
    return direction;
}

float DielectricReflectance(float cosine, float ref_idx)
{
    // Use Schlick's approximation for reflectance.
    float r0 = (1.0f - ref_idx) / (1.0f + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0f - r0) * pow((1.0f - cosine), 5.0f);
}


vec3 Refract(Ray ray, vec3 normal, float etai_over_etat, out bool valid)
{
    vec3 refractedRay;

	vec3 uv = normalize(ray.dir);
	float dt = dot(ray.dir, normal);
	float discriminant = 1 - etai_over_etat * etai_over_etat * (1 - dt * dt);

	if (discriminant <= 0)
	{
        valid = false;
		return vec3(0, 0, 0);
	}

    valid = true;
	refractedRay = etai_over_etat * (uv - normal * dt) - normal * sqrt(discriminant);
	return refractedRay;
}


vec3 GetSphereExitPoint(vec3 p, vec3 d, vec3 center, float radius) 
{
    vec3 m = p - center;

    float b = 2.0 * dot(m, d);
    float c = dot(m, m) - radius * radius;

    float discriminant = b * b - 4.0 * c;

    if (discriminant < 0.0) {
        // No intersection; ray misses the sphere (shouldn't happen if p is on surface)
        return vec3(0.0); // or some error marker
    }

    float sqrtDiscriminant = sqrt(discriminant);
    float t1 = (-b - sqrtDiscriminant) * 0.5;
    float t2 = (-b + sqrtDiscriminant) * 0.5;

    float tExit = (t1 > 0.0001) ? t1 : t2; // ignore the zero or near-zero root (the starting point)

    return p + tExit * d;
}