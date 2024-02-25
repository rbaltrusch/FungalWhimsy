return [[
// defines medium precision of floats for decent precision at decent speed
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_factor;
uniform float u_time;
uniform float u_death_time;
uniform float u_offset;

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 texture_coords) {
    vec4 texture = Texel(image, uvs);
    vec2 scaled_position = texture_coords / u_resolution;
    if (scaled_position.x < (u_death_time)) {
        return vec4(0.0, 0.0, 0.0, 1);
    }
    float pulse = 0.07 * sin(u_time);
    vec2 middle = vec2(0.5, 0.5);
    float dist = distance(middle, scaled_position);
    float factor = min(1.1, - log(dist + pulse + u_offset));
    return vec4(texture.rgb * factor, texture.a);
}
]]
