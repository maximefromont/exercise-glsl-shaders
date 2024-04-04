//GLOBAL CONSTANTS--------------------//
const float PI = 3.14159;
const float MOVEMENT_SPEED = -10.;
const float TIME_DAMPENING = -800.0;

//NOISES METHODS----------------------//

#define S(a, b, t) smoothstep(a, b, t)

float hash(vec2 x)
{
    return fract(sin(dot(x, vec2(12.9898, 78.233)))* 43758.5453);
}

float coefA(vec2 ij)
{
    float u = 50. * fract(ij.x / PI);
    float v = 50. * fract(ij.y / PI);
    return hash(vec2(u, v));
}

float coefB(vec2 ij) 
{ 
    return coefA(ij + vec2(1., 0.)); 
}

float coefC(vec2 ij) 
{ 
    return coefA(ij + vec2(0., 1.)); 
}

float coefD(vec2 ij) 
{ 
    return coefA(ij + vec2(1., 1.)); 
}

float AUGH(float lambda) 
{ 
	return 3. * pow(lambda, 2.) - 2. * pow(lambda, 3.); 
}

float snoise(vec3 pos)
{
    vec2 xz = pos.xz;
    vec2 ij = vec2(floor(xz.x), floor(xz.y));
    float i = ij.x;
    float j = ij.y;
    float x = xz.x;
    float z = xz.y;
    float a = coefA(ij);
    float b = coefB(ij);
    float c = coefC(ij);
    float d = coefD(ij);
    return a +
           (b - a) * AUGH(x - i) +
           (c - a) * AUGH(z - j) +
           (a - b - c + d) * AUGH(x - i) * AUGH(z - j);
}

//SHAPES METHODS----------------------//

//This is a Minkowski distance method
float len(vec3 point, float order) 
{
    //Len settings
    const float LEN_RATIO = 1.0;

	point = pow(abs(point), vec3(order));
	return pow(point.x + point.y + point.z, LEN_RATIO/order);
}

//This is used to create the sphere
float Sphere(vec3 position, float radius) 
{
    //Sphere settings
    const float SPHERE_SHAPE = 2.0; //1.0 = Triangle, 2.0 = Sphere, 100.0 = Rectangle

	return len(position, SPHERE_SHAPE) - radius;
}

//MAP CREATION-------------------------//

float map(vec3 position) 
{
    //Map settings
    const float MAP_FLOOR_NOISE_FREQUENCY = 0.4;
    const float MAP_FLOOR_NOISE_AMPLITUDE = 2.0;
    const float MAP_SPHERE_HEIGHT = 2.0;
    const float MAP_SPHERE_RADIUS = 1.5;

    //Variables
    float movement_offset = (iTime+TIME_DAMPENING)*MOVEMENT_SPEED; //Be careful, movement offset is (in this case) already negative

    //Creation of the floor
	float floor = position.y - (snoise(position * MAP_FLOOR_NOISE_FREQUENCY) * MAP_FLOOR_NOISE_AMPLITUDE);

    //Creation of the sphere (using the floor)
    vec3 spherePosition = position - vec3(movement_offset, MAP_SPHERE_HEIGHT, 0.0) + vec3(0.0, floor, 0.0);
	float sphereDistance = Sphere(spherePosition, MAP_SPHERE_RADIUS);

    //Union of the floor and the sphere
    return min(sphereDistance, floor);
}

//RAY TRACING METHODS-------------------//

float rayMarch(vec3 ro, vec3 rd, float m) 
{
    //RayMarch settings
    const float RAYMARCH_MINIMUM_DISTANCE = 0.001;
    const float RAYMARCH_DISTANCE_MULTIPLIER = 0.0001;
    const int RAYMARCH_MAX_ITERATIONS = 200;
    const float RAYMARCH_RATIO = 0.67;

    //Variables
	float tracing = 0.0;
    int i;

	for(i = 0; i < RAYMARCH_MAX_ITERATIONS; i++) 
    {
		float d = map(ro + rd*tracing);
		if(d < (RAYMARCH_MINIMUM_DISTANCE + RAYMARCH_DISTANCE_MULTIPLIER*tracing) || tracing >= m) break;
		tracing += d*RAYMARCH_RATIO;
	}

	return tracing;
}

vec3 normal(vec3 position) 
{
    //Global settings
    const vec2 NORMAL_OFFSET = vec2(0.01, 0.0);

	vec3 n = vec3(
		map(position + NORMAL_OFFSET.xyy) - map(position - NORMAL_OFFSET.xyy),
		map(position + NORMAL_OFFSET.yxy) - map(position - NORMAL_OFFSET.yxy),
		map(position + NORMAL_OFFSET.yyx) - map(position - NORMAL_OFFSET.yyx)
	);

	return normalize(n);
}

float ambientOcclusion(vec3 position, vec3 normal) 
{
    //AmbientOcclusion settings
    const int AMBIENT_OCCLUSION_ITERATIONS = 15;
    const float AMBIENT_OCCLUSION_DAMPING_FACTOR = 0.98;
    const float AMBIENT_OCCLUSION_MIN_VALUE = 0.0;
    const float AMBIENT_OCCLUSION_MAX_VALUE = 1.0;
    const float AMBIENT_OCCLUSION_BASE_VALUE = 1.0;

    //Variables
	float occlusionAmmount = 0.0;
    float stepSize = 0.005;
    float weight = 1.0;
    float distance;
    int i;
	
	for(i = 0; i < AMBIENT_OCCLUSION_ITERATIONS; i++) {
		distance = map(position + normal*stepSize);
		occlusionAmmount += (stepSize - distance)*weight;
		weight *= AMBIENT_OCCLUSION_DAMPING_FACTOR;
		stepSize += stepSize/float(i + 1);
	}
	
	return AMBIENT_OCCLUSION_BASE_VALUE - clamp(occlusionAmmount, AMBIENT_OCCLUSION_MIN_VALUE, AMBIENT_OCCLUSION_MAX_VALUE);
}

//CAMERA METHODS-----------------------//
mat3 createCameraMatrix(vec3 origin, vec3 lookAtPoint) 
{
    //CreateCameraMatrix settings
    const vec3 CAMERA_MATRIX_UP_DIRECTION_VECTOR = vec3(0, 1, 0);

    //Variables
    vec3 forwardDirection;
    vec3 rightDirection;
    vec3 upDirection;

	forwardDirection = normalize(lookAtPoint - origin);
	rightDirection = normalize(cross(CAMERA_MATRIX_UP_DIRECTION_VECTOR, forwardDirection));
	upDirection = normalize(cross(forwardDirection, rightDirection));
	
	return mat3(rightDirection, upDirection, forwardDirection);
}

//This method was created by the teacher in the example he created in lecture 2, I left it untouched
vec3 localRay;
void CamPolar(out vec3 pos, out vec3 ray, in vec3 origin, in vec2 rotation, in float distance, in float zoom, in vec2 fragCoord) 
{
    vec2 c = vec2(cos(rotation.x), cos(rotation.y));
    vec4 s;
    s.xy = vec2(sin(rotation.x), sin(rotation.y));
    s.zw = -s.xy;

    ray.xy = fragCoord.xy - iResolution.xy * .5;
    ray.z = iResolution.y * zoom;
    ray = normalize(ray);
    localRay = ray;

    ray.yz = ray.yz * c.xx + ray.zy * s.zx;
    ray.xz = ray.xz * c.yy + ray.zx * s.yw;

    pos = origin - distance * vec3(c.x * s.y, s.z, c.x * c.y);
}

//MAIN--------------------------------//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
	
	vec3 ro = vec3(4.5, 2.5, 0);
	vec3 rd = createCameraMatrix(ro, vec3(0., 0., 0.))*normalize(vec3(p, 1.97));
	
    vec2 camRot = vec2(0.5, 0.) + vec2(-.35, 4.5) * (iMouse.yx / iResolution.yx);
    CamPolar(ro, rd, vec3(0., 1.5, 0), camRot, 10., 1.0, fragCoord);

    //This line is used to make the camera moves at the same speed and same rate as the sphere does.
    //This whole movement thing could probably be made much more efficiently (or easier at least) if the floor was moving instead.
    float movement_offset = (iTime+TIME_DAMPENING)*MOVEMENT_SPEED;
	ro = vec3(ro.x + movement_offset,ro.y, ro.z);

	vec3 col = vec3(0.45, 0.8, 1.0);
	vec3 lig = normalize(vec3(0.8, 0.7, -0.6));
	
	for(int i = 0; i < 3; i++) {
		float t = rayMarch(ro, rd, 50.0);
		if(t < 50.0) {
			vec3 rcol = vec3(0);
			
			vec3 pos = ro + rd*t;
			vec3 nor = normal(pos);
			vec3 ref = reflect(rd, nor);
			
            //Shadows
			float occ = ambientOcclusion(pos, nor);
			float sha = step(5.0, rayMarch(pos + nor*0.001, lig, 5.0));
			
            //Lighting
			rcol += 0.2*occ;
			rcol += clamp(dot(lig, nor), 0.0, 1.0)*occ*sha;
			rcol += pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 2.0)*occ;
			rcol += 2.0*pow(clamp(dot(ref, lig), 0.0, 1.0), 30.0)*occ;
			
            //Texture and colors
			if(pos.y > -0.99)
				rcol *= vec3(2.2, 0.7, 0.7);
			else
				rcol *= 0.3 + 0.7*mod(floor(pos.x) + floor(pos.z), 2.0); //I am not using this, it was for the first version
			
            //Ro & rd initialization
			ro = pos + nor*0.001;
			rd = ref;
			
            //Fog
			rcol = mix(rcol, vec3(0.0, 0.8, 1.0), 1.0 - exp(-0.1*t));
			
            //This is important to limit the reflections on each iteration
			if(i == 0) col = rcol;            
			else col *= mix(rcol, vec3(1), 1.0 - exp(-0.8*float(i)));
		}
	}
	
    //Gamma correction
	col = 1.0 - exp(-0.5*col);
	col = pow(abs(col), vec3(1.0/2.2));
	
	fragColor = vec4(col, 1);
}