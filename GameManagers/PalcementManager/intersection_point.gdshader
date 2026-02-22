shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled;

// ==========================================
// 🎨 材质检查器里的调参区
// ==========================================
uniform vec4 valid_color : source_color = vec4(0.1, 1.0, 0.1, 0.8);
uniform vec4 invalid_color : source_color = vec4(1.0, 0.1, 0.1, 0.9);
uniform float line_thickness : hint_range(0.001, 0.2) = 0.02;
uniform float line_length : hint_range(0.01, 0.5) = 0.25;

// === 🔥 核心修复：搭建一座桥梁，把数据传给片元 ===
varying vec4 custom_data;

void vertex() {
    // 在顶点阶段读取外部传入的 Custom Data，并交给桥梁
    custom_data = INSTANCE_CUSTOM;
}

void fragment() {
    vec2 uv = UV - 0.5;
    
    // 画十字架
    float horizontal = step(abs(uv.y), line_thickness) * step(abs(uv.x), line_length);
    float vertical = step(abs(uv.x), line_thickness) * step(abs(uv.y), line_length);
    float cross_mask = clamp(horizontal + vertical, 0.0, 1.0);
    
    // ==========================================
    // 🧠 使用从桥梁(custom_data)传过来的数据！
    // custom_data.r 存的是是否被占用 (0.0=空闲, 1.0=占用)
    // custom_data.g 存的是探照灯透明度衰减
    // ==========================================
    vec4 base_color = mix(valid_color, invalid_color, custom_data.r);
    
    ALBEDO = base_color.rgb;
    ALPHA = base_color.a * custom_data.g * cross_mask;
}