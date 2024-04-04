float distortAmount = 0.004;
float distortZoom = 1.2;
float distortSpeed = 0.1;
float lerpIntensity = 0.6;

vec3 mainColor = vec3(0.5, 0.45, 0.4) * 0.8;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    float distortNoise = texture(iChannel1, vec2(fract(uv.x * distortZoom - iTime * distortSpeed), uv.y * distortZoom)).r;
    
    distortNoise = smoothstep(0.11, 0.45, distortNoise);

    vec2 distortUV = (vec2(distortNoise * 1., distortNoise * 1.) * distortAmount);
    
    vec4 color = texture(iChannel0, uv + distortUV);
    
    float sandNoise = texture(iChannel2, vec2(fract(uv.x - iTime * 0.8), fract(uv.y + iTime * 0.055)) + distortUV).r;
    float sandNoise2 = texture(iChannel2, vec2(fract(uv.x * 1.2 - iTime * 0.4), fract(uv.y * 1.2 + iTime * 0.06)) + distortUV).r;
    float sandNoise3 = texture(iChannel2, vec2(fract(uv.x * 0.8 - iTime * 0.6), fract(uv.y * 0.8 + iTime * 0.035)) + distortUV).r;

    float finalSandNoise = sandNoise * 0.233 + sandNoise2 * 0.433 + sandNoise3 * 0.333;
    float sineLerpModifier = (1. + sin(3.1415 * iTime * 0.4)) * 0.1;
    color = mix(color, vec4(mainColor, 1.), lerpIntensity * sineLerpModifier);
    color += vec4(mainColor, 1.) * mix(0.2, 1.0, finalSandNoise * mix(0.5, 0.9, sineLerpModifier));

    //Blending the sandstorm with the shader using the alpha channel
    fragColor = mix(fragColor, color, 1.);
}