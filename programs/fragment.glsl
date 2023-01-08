#version 330 core
layout(location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform float u_time;

const int MAX_STEPS = 300;
const float MAX_DIST = 50;
const float EPSILON = 0.0001;
const float PI = acos(-1.0);


mat2 rot(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca, -sa, sa, ca);
}


float getSphere(vec3 p, float r) {
    return length(p) - r;
}


float getBox(vec3 p, float size) {
    p = abs(p) - size;
    return max(p.x, max(p.y, p.z));
}


float getCross(vec3 p, float size) {
    p = abs(p) - size / 3.0;
    float bx = max(p.y, p.z);
    float by = max(p.x, p.z);
    float bz = max(p.x, p.y);
    return min(min(bx, by), bz);
}


float getInnerMenger(vec3 p, float size) {
    float d = EPSILON;
    float scale = 1.0;
    for (int i = 0; i < 4; i++) {
        float r = size / scale;
//        vec3 q = mod(p + r, 2.0 * r) - r;
        vec3 q = mod(p * (i + 1.0 * scale) / (2.0 * scale) + r, 2.0 * r) - r;
        d = min(d, getCross(q, r));
        scale *= 3.0;
    }
    return d;
}


vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}


float hash13(vec3 p) {
	p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}


vec4 map(vec3 p) {
    float d = 0.0;
    float size = 0.5;
    vec3 col = vec3(1);

    p.z += u_time * 0.3;
    p.xy *= rot(u_time * 0.1);

    d = -getInnerMenger(p, size);

//    col = abs(floor(p * 6.0 * size - size) + 0.1);
    col = hash33(floor(p * 3.0 * size - size) + 2e-5 * u_time);
//    col = vec3(hash13(floor(p * 3.0 * size - 1.0 * size)));
    return vec4(col, d * 0.9);
}


vec4 rayMarch(vec3 ro, vec3 rd, int steps) {
    float dist; vec3 p; vec3 col;
    for (int i; i < steps; i++) {
        p = ro + rd * dist;
        vec4 res = map(p);
        col = res.rgb;
        if (res.w < EPSILON) break;
        dist += res.w;
        if (dist > MAX_DIST) break;
    }
    return vec4(col, dist);
}


float getAO(vec3 pos, vec3 norm) {
    float AO_SAMPLES = 10.0;
    float AO_FACTOR = 1.0;
    float result = 1.0;
    float s = -AO_SAMPLES;
    float unit = 1.0 / AO_SAMPLES;
    for (float i = unit; i < 1.0; i += unit) {
        result -= pow(1.6, i * s) * (i - map(pos + i * norm).w);
    }
    return result * AO_FACTOR;
}


vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = map(p).w - vec3(map(p - e.xyy).w, map(p - e.yxy).w, map(p - e.yyx).w);
    return normalize(n);
}


vec3 render(vec2 uv) {
    vec3 col = vec3(0);
    vec3 ro = vec3(0, 0, -1.9);
    vec3 rd = normalize(vec3(uv, 2.0));

    mat2 rm = rot(PI * 0.5 + u_time * 0.25);
    rd.xy *= rm;
    rd.xz *= rm;

    vec4 res = rayMarch(ro, rd, MAX_STEPS);

    if (res.w < MAX_DIST) {
        vec3 p = ro + rd * res.w;
        vec3 normal = getNormal(p);

        // shading
        float diff = 0.7 * max(0.0, dot(normal, -rd));
        vec3 ref = reflect(rd, normal);
//        float spec = max(0.0, pow(dot(ref, -rd), 32.0));
        float ao = getAO(p, normal);
//        col += (spec + diff) * ao * res.rgb;

        // reflections
        vec3 ref_col;
        vec4 ref_res = rayMarch(p + normal * 0.05, ref, 15);
        vec3 ref_p = p + ref * ref_res.w;
        vec3 ref_normal = getNormal(ref_p);
        ref_col = ref_res.rgb * max(0.0, dot(-ref, ref_normal));

//        col = 0.1 * ref_col + 0.9 * col;
        col = ref_col * ao;

        // fog
        vec3 c = abs(floor(p + 6.0));
        col = mix(c * 0.4, col, exp(-0.03 * res.w * res.w));
    }
    return col;
}



void main() {
    vec2 uv = 2.0 * gl_FragCoord.xy - u_resolution.xy;
    uv /= u_resolution.y;
    vec3 col = render(uv);

    fragColor = vec4(sqrt(col), 1.0);
}