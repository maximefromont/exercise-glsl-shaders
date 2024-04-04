vec3 drawRotatingWheelTireAndSpokes(vec2 center, vec2 uv, float radius, float tireRadius, float time, float speed, vec3 backgroundColor) 
{
    float angle = time * speed;
    mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 rotatedUV = rotate * (uv - center) + center;
    
    float wheelDistance = length(rotatedUV - center);
    float tire = smoothstep(tireRadius - 0.02, tireRadius + 0.02, wheelDistance);
    
    float spokeRadius = radius * 0.7;
    float spokeDistance = length(rotatedUV - center);
    float spokeAngle = atan(rotatedUV.y - center.y, rotatedUV.x - center.x);
    float spokePattern = step(0.1, abs(fract(spokeAngle / 3.14159265 * 4.0) - 0.5)) * step(spokeDistance, spokeRadius);
    
    float inTire = 1.0 - smoothstep(tireRadius - 0.02, tireRadius, wheelDistance);
    float spokeTransparency = -1.0 - spokePattern;
    
    vec3 wheelColor = vec3(0.1);
    vec3 finalColor = mix(backgroundColor, wheelColor, (inTire) * spokeTransparency);
    
    return finalColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    vec3 skyColor = vec3(0.4, 0.6, 0.9);
    vec3 groundColor = vec3(0.0, 0.5, 0.0);
    
    float speedMultiplier = 20.0;
    float speed = (iMouse.x / iResolution.x) * speedMultiplier - (speedMultiplier / 2.0);
    
    vec3 backgroundColor = mix(groundColor, skyColor, smoothstep(-0.2, 0.2, uv.y));
    
    float elementPosition = fract(iTime * speed * 0.1);
    
    float cloudBase = smoothstep(0.3, 0.5, uv.y);
    float cloudPattern = 0.0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -1; j <= 1; ++j) {
            vec2 cloudPos = vec2(float(i) * 0.25, float(j) * 0.15) + vec2(elementPosition, 0.0);
            cloudPattern += smoothstep(0.02, 0.03, 0.1 - length(uv - cloudPos));
        }
    }
    vec3 cloudColor = mix(backgroundColor, vec3(1.0), min(cloudPattern, 1.0) * cloudBase);
    
    float treePattern = smoothstep(0.02, 0.03, abs(fract(uv.x * 5.0 + elementPosition) - 0.5));
    vec3 treeColor = mix(backgroundColor, vec3(0.55, 0.27, 0.07), treePattern * smoothstep(-0.3, 0.0, uv.y));
    
    vec2 headlightRight = vec2(0.4, -0.18);
    float headlightRightCone = max(0.0, 1.0 - length(uv - headlightRight) * 7.0);
    vec3 headlightColor = vec3(1.0, 0.8, 0.6) * (headlightRightCone);

    vec2 tailLight = vec2(-0.4, -0.18);
    float tailLightCone = max(0.0, 1.0 - length(uv - tailLight) * 7.0);
    vec3 tailLighColor = vec3(1.0, 0.0, 0.0) * (tailLightCone);

    float carBody = length(max(abs(uv - vec2(0.0, -0.25)) - vec2(0.4, 0.1), 0.0)) - 0.010;
    float carNose = length(max(abs(uv - vec2(0.0, -0.15)) - vec2(0.2, 0.1), 0.0)) - 0.08;
    float car = min(carBody, carNose);
    
    vec2 cabOffset = vec2(0.0, -0.065);
    float cabWidth = 0.2;
    float cabHeight = 0.025;
    float cab = length(max(abs(uv - cabOffset) - vec2(cabWidth, cabHeight), 0.0)) - 0.02;
    float isCab = step(cab, 0.0);
    
    vec3 color = mix(treeColor, cloudColor, step(car, 0.0));
    
    vec3 leftWheelTireSpokes = drawRotatingWheelTireAndSpokes(vec2(-0.25, -0.35), uv, 0.1, 0.12, iTime, -speed, color);
    vec3 rightWheelTireSpokes = drawRotatingWheelTireAndSpokes(vec2(0.25, -0.35), uv, 0.1, 0.12, iTime, -speed, color);
    color = mix(color, vec3(0.2), max(leftWheelTireSpokes, rightWheelTireSpokes));

    color = mix(color, headlightColor, headlightRightCone);
    color = mix(color, tailLighColor, tailLightCone);
    
    if (isCab > 0.0) {
        color = mix(color, vec3(1.0), isCab);
    }
    
    if (car < 0.0 && isCab == 0.0) color = vec3(1.0, 0.0, 0.0);
    
    fragColor = vec4(color, 1.0);
}
