shader_type spatial;
// 加上 depth_test_disabled 确保网格永远显示在最上层
render_mode unshaded, blend_mix, depth_test_disabled; 

uniform vec4 line_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.05, 0.05, 0.05, 0.0); //
uniform float line_thickness : hint_range(0.001, 0.1) = 0.01;

// --- 动态参数 ---
uniform float base_grid_size = 1.0;          
uniform vec2 active_item_cells = vec2(1.0);  
uniform bool is_terrain_mode = false;        
uniform float cross_size : hint_range(0.01, 0.5) = 0.15;
uniform float dash_gap = 0.2;

// =====================================
// 🔥 新增：手电筒探照灯参数
// =====================================
uniform vec3 mouse_world_pos = vec3(0.0);
uniform float show_radius = 10.0; // 10米半径，直径20米，刚好覆盖 20x20 范围

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 world_normal = abs((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz); //

    vec3 blend = normalize(max(world_normal, vec3(0.00001)));
    blend /= dot(blend, vec3(1.0));
    vec2 current_size = base_grid_size * active_item_cells; //

    vec3 local;
    local.x = fract(world_pos.x / current_size.x + 0.5) - 0.5; //
    local.y = 0.0;
    local.z = fract(world_pos.z / current_size.y + 0.5) - 0.5; //

    vec3 abs_local = abs(local);
    vec3 borders = step(abs_local, vec3(line_thickness));
    vec3 within_cross = step(abs_local, vec3(cross_size)); //

    float final_mask = 0.0;

    if (!is_terrain_mode) {
        float mask_x = max(borders.y * within_cross.z, borders.z * within_cross.y);
        float mask_y = max(borders.x * within_cross.z, borders.z * within_cross.x); //
        float mask_z = max(borders.x * within_cross.y, borders.y * within_cross.x);
        final_mask = mask_x * blend.x + mask_y * blend.y + mask_z * blend.z; //
    } else { //
        float dash_x = step(0.5, fract(world_pos.x / dash_gap));
        float dash_z = step(0.5, fract(world_pos.z / dash_gap)); //
        borders.x *= dash_z;
        borders.z *= dash_x;

        float grid_x = max(borders.y, borders.z);
        float grid_y = max(borders.x, borders.z); //
        float grid_z = max(borders.x, borders.y);
        final_mask = grid_x * blend.x + grid_y * blend.y + grid_z * blend.z; //
    }

    final_mask = step(0.1, final_mask); //

    // =====================================
    // 🔥 核心计算：探照灯距离衰减蒙版
    // =====================================
    float dist = distance(world_pos.xz, mouse_world_pos.xz);
    // 从半径内围(8米)到外围(10米)产生柔和的渐隐消失效果
    float circle_mask = 1.0 - smoothstep(show_radius - 2.0, show_radius, dist);

    ALBEDO = mix(bg_color.rgb, line_color.rgb, final_mask);
    // 原有的线条透明度，乘以圆圈蒙版，实现范围外彻底隐形！
    ALPHA = mix(bg_color.a, line_color.a, final_mask) * circle_mask;
}