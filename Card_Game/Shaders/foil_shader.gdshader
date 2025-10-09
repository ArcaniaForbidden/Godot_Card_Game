shader_type canvas_item;

uniform vec4 foil_color = vec4(1.0, 1.0, 0.8, 0.3);
uniform float streak_width = 0.2;
uniform vec2 screen_pos = vec2(0.5, 0.5);   // set by GDScript
uniform float streak_speed = -0.2;          // speed of streak over time
uniform bool rainbow_mode = false;
uniform float hue_speed = 0.3;              // hue rotation speed for rainbow

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 uv = UV;
    vec4 tex = texture(TEXTURE, uv); // Sample the card’s texture

    // Diagonal streak that moves with screen position + time
    float diag = uv.x + uv.y + screen_pos.x + screen_pos.y + TIME * streak_speed;
    float streak = smoothstep(0.0, streak_width, fract(diag)) *
                   smoothstep(1.0, 1.0 - streak_width, fract(diag));

    // Base color for foil
    vec3 base_rgb = foil_color.rgb;
    if (rainbow_mode) {
        float hue = fract(TIME * hue_speed);
        base_rgb = hsv2rgb(vec3(hue, 1.0, 1.0));
    }

    // Multiply foil alpha by the texture’s alpha so it only appears on visible pixels
    float alpha = tex.a * (foil_color.a * 0.2 + streak * foil_color.a);

    // Output color
    COLOR = vec4(base_rgb, alpha);
}
