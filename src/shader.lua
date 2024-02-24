return [[
// defines medium precision of floats for decent precision at decent speed
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_factor;
uniform float u_time;

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 texture_coords) {
    vec4 texture = Texel(image, uvs);
    float pulse = 0.07 * sin(u_time);
    vec2 middle = vec2(0.5, 0.5);
    float dist = distance(middle, texture_coords / u_resolution);
    float factor = min(1.1, - log(dist + pulse));
    return texture.rgba * factor;
}
]]
