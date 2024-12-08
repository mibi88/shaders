/* Simple sphere raymarching in Shadertoy
 * (c) 2024 Mibi88
 *
 * Look around with the mouse and press 'Q' (or 'A' on AZERTY keyboards) to
 * move forwards or backwards by moving the mouse cursor on the Y axis.
 *
 * This software is licensed under the BSD-3-Clause license:
 *
 * Copyright 2024 Mibi88
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#define NAIVE_RAYMARCHING 0

#define SPHERE_NUM 4
#define STEP 0.1
#define MAX 100.0
#define FADE 100.0

bool read_key(int key) {
    return textureLod(iChannel0,
                      vec2((float(key)+0.5)/256.0, 0.25), 0.0).x > 0.5;
}

vec3 cameraPos = vec3(0.0);

vec3 spheres[SPHERE_NUM] = vec3[SPHERE_NUM](
    vec3(-8.0, 1.0, 15.0),
    vec3(3.0, 0.0, 10.0),
    vec3(0.0, 0.0, 22.0),
    vec3(16.0, 3.0, 7.0)
);

float sphereSizes[SPHERE_NUM] = float[SPHERE_NUM](
    2.0,
    1.1,
    3.5,
    5.0
);

vec3 sphereColors[SPHERE_NUM] = vec3[SPHERE_NUM](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0),
    vec3(1.0, 1.0, 0.0)
);

float distance_function(vec3 p, int idx){
    return distance(p, spheres[idx])-sphereSizes[idx];
}

vec4 raycast(float angleX, float angleY) {
    vec3 pos = cameraPos;
    vec3 dir;
    dir.z = cos(angleX)*cos(angleY);
    dir.x = sin(angleX)*cos(angleY);
    dir.y = sin(angleY);
#if NAIVE_RAYMARCHING
    for(float len=0.0;len<MAX;len+=STEP){
        float sin_rx = sin(angleX+radians(90.0));
        pos += dir*STEP;
        for(int s=0;s<SPHERE_NUM;s++){
            float dist = distance_function(pos, s);
            if(dist < STEP){
                return vec4(max(sphereColors[s]-
                                distance_function(cameraPos, s)/FADE,
                                vec3(0.0, sin(angleY)*0.4+0.5,
                                     sin(angleY)*0.5+0.5)),
                            1.0);
            }
        }
    }
#else
    float total_len = 0.0;
    for(int n=0;n<int(MAX/STEP);n++){
        float len = MAX;
        for(int s=0;s<SPHERE_NUM;s++){
            float new_len = distance_function(pos, s);
            if(new_len < STEP){
                return vec4(max(sphereColors[s]-total_len/FADE,
                                vec3(0.0, sin(angleY)*0.4+0.5,
                                     sin(angleY)*0.5+0.5)),
                            1.0);
            }
            if(new_len < len) len = new_len;
        }
        total_len += len;
        pos += dir*len;
        if(total_len > MAX) break;
    }
#endif
    return vec4(0.0, sin(angleY)*0.4+0.5, sin(angleY)*0.5+0.5, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float fov = 60.0;
    float y_angle = iResolution.y/iResolution.x*fov;

    vec2 uv = fragCoord/iResolution.xy;

    float cameraAngleX = (iMouse.x-iResolution.x/2.0)/iResolution.x*
                                                                radians(360.0);
    float cameraAngleY = (iMouse.y-iResolution.y/2.0)/iResolution.y*
                                                                radians(360.0);
    
    if(read_key(65)){
        cameraAngleY = 0.0;
        cameraPos.z += cos(cameraAngleX)*cos(cameraAngleY)*
                                        (iMouse.y/iResolution.y*FADE*2.0-FADE);
        cameraPos.x += sin(cameraAngleX)*cos(cameraAngleY)*
                                        (iMouse.y/iResolution.y*FADE*2.0-FADE);
        cameraPos.y += sin(cameraAngleY)*
                                        (iMouse.y/iResolution.y*FADE*2.0-FADE);
    }

    fragColor = raycast(radians(fov)*(fragCoord.x/iResolution.x)-
                                                radians(fov/2.0)+cameraAngleX,
                        radians(y_angle)*(fragCoord.y/iResolution.y)-
                                            radians(y_angle/2.0)+cameraAngleY);
}

