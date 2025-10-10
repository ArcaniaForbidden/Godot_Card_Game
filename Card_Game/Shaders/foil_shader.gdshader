shader_type canvas_item;

uniform vec4 foil_color = vec4(1.0, 1.0, 0.8, 0.3);
uniform float streak_width = 0.5;
uniform vec2 screen_pos = vec2(0.5, 0.5);       // set by GDScript
uniform float streak_speed = -0.2;             // speed of streak over time
uniform bool rainbow_mode = false;
uniform float hue_speed = 0.3;                 // hue rotation speed for rainbow
uniform float block_width = 4.0;               // pixel block width
uniform float block_height = 4.0;              // pixel block height

const float CARD_W = 98.0;
const float CARD_H = 140.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 uv = UV;
    // --- Pixelated UV ---
    vec2 uv_px;
    uv_px.x = floor(uv.x * CARD_W / block_width) * block_width / CARD_W;
    uv_px.y = floor(uv.y * CARD_H / block_height) * block_height / CARD_H;
    // --- Sample the card texture ---
    vec4 tex = texture(TEXTURE, uv);
    // --- Diagonal streak ---
    float diag = uv_px.x + uv_px.y + screen_pos.x + screen_pos.y + TIME * streak_speed;
    float streak = smoothstep(0.0, streak_width * 0.5, fract(diag)) *
                   smoothstep(1.0, 1.0 - streak_width * 0.5, fract(diag));
    // --- Base color ---
    vec3 base_rgb = foil_color.rgb;
    // --- Rainbow mode (subtle) ---
    if (rainbow_mode) {
        float hue = fract(TIME * hue_speed + diag); // diagonal variation for shimmer
        base_rgb = hsv2rgb(vec3(hue, 0.5, 0.8));   // lower saturation/value
    }
    // --- Streak color (brighter than base, subtle) ---
    vec3 streak_rgb = mix(base_rgb, vec3(1.0), 0.3);
    // --- Foil alpha with texture ---
    float alpha = tex.a * (foil_color.a * 0.2 + streak * foil_color.a * 0.8);
    // --- Output color ---
    COLOR = mix(vec4(base_rgb, alpha), vec4(streak_rgb, alpha), streak);
}
