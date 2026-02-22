shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// 1. 模具遮罩图 (Sprite3D 本身的贴图)
uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap;

// 2. 边框贴纸图 (新加的独立图)
uniform sampler2D border_texture : source_color, filter_linear_mipmap;

// 3. 大尺度肌理图 (木板底纹)
uniform sampler2D fill_texture : source_color, filter_linear_mipmap; 
uniform float fill_scale : hint_range(0.001, 1.0) = 0.1;

uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. 读取遮罩图 (只借用它的形状/Alpha通道)
	vec4 mask_color = texture(texture_albedo, UV);

	// 裁剪掉遮罩外面的透明区域
	if (mask_color.a < alpha_scissor_threshold) {
		discard;
	}
	ALPHA = mask_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;

	// 2. 读取大肌理图 (计算世界坐标)
	vec2 world_uv = world_pos.xz * fill_scale;
	vec4 fill_color = texture(fill_texture, world_uv);

	// 3. 读取边框贴纸图
	vec4 border_color = texture(border_texture, UV);

	// 🌟 4. 终极完美混合
	// 先把底色设为木板肌理
	vec3 final_color = fill_color.rgb;
	// 利用边框图的 Alpha 透明度作为浆糊，把边框死死贴在木板上！
	// 如果边框有半透明的柔边笔刷，mix 函数会自动完美地融入底下的木板，绝无白边！
	final_color = mix(final_color, border_color.rgb, border_color.a);

	ALBEDO = final_color;
}