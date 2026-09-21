shader_type canvas_item;

uniform sampler2D current_tex : source_color;
uniform sampler2D background_tex : source_color;

// usado somente para fazer a troca final
// entre o background do SubViewport e a cena principal.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float fall_progress : hint_range(0.0, 1.0) = 0.0;

// controla a transicao final para a cena principal.
uniform float final_blend : hint_range(0.0, 1.0) = 0.0;


uniform int pieces_x = 5;
uniform int pieces_y = 3;


uniform float gravity : hint_range(0.5, 3.0) = 1.15;
uniform float scatter : hint_range(0.0, 1.0) = 0.22;
uniform float rotation_amount : hint_range(0.0, 4.0) = 1.0;


uniform float point_jitter : hint_range(0.0, 0.48) = 0.34;
uniform float delay_variation : hint_range(0.0, 0.8) = 0.28;


uniform float exit_margin : hint_range(0.0, 1.0) = 0.35;


uniform float edge_thickness : hint_range(0.0005, 0.05) = 0.01;
uniform float edge_brightness : hint_range(0.0, 2.0) = 0.35;


uniform float alpha_fade_start : hint_range(0.0, 1.0) = 1.0;


const int SEARCH_RADIUS = 1;
const int MAX_ROWS = 32;


float hash12(vec2 p) {
	vec3 p3 = fract(
		vec3(p.xyx) *
		0.1031
	);

	p3 += dot(
		p3,
		p3.yzx + 33.33
	);

	return fract(
		(p3.x + p3.y) *
		p3.z
	);
}


vec2 hash22(vec2 p) {
	return vec2(
		hash12(
			p + vec2(1.23, 4.56)
		),
		hash12(
			p + vec2(7.89, 0.12)
		)
	);
}


mat2 rot(float a) {
	float s = sin(a);
	float c = cos(a);

	return mat2(
		vec2(c, -s),
		vec2(s, c)
	);
}


vec2 cell_point(vec2 cell_id) {
	vec2 h =
		hash22(cell_id);

	return cell_id +
		0.5 +
		(h - 0.5) *
		(point_jitter * 2.0);
}


void voronoi_info(
	vec2 p,
	out vec2 owner_cell,
	out vec2 owner_point,
	out float edge_dist
) {
	vec2 base =
		floor(p);

	float best_d =
		1e20;

	float second_d =
		1e20;

	vec2 best_cell =
		vec2(0.0);

	vec2 best_point =
		vec2(0.0);


	for (
		int j = -SEARCH_RADIUS;
		j <= SEARCH_RADIUS;
		j++
	) {

		for (
			int i = -SEARCH_RADIUS;
			i <= SEARCH_RADIUS;
			i++
		) {

			vec2 c =
				base +
				vec2(
					float(i),
					float(j)
				);

			vec2 pt =
				cell_point(c);

			float d =
				distance(
					p,
					pt
				);


			if (d < best_d) {

				second_d =
					best_d;

				best_d =
					d;

				best_cell =
					c;

				best_point =
					pt;

			} else if (d < second_d) {

				second_d =
					d;
			}
		}
	}


	owner_cell =
		best_cell;

	owner_point =
		best_point;

	edge_dist =
		second_d -
		best_d;
}


void piece_transform(
	vec2 piece_cell,
	vec2 point,
	vec2 grid,

	out float t,
	out vec2 piece_offset_uv,
	out float piece_angle
) {
	float rnd =
		hash12(piece_cell);

	float rnd2 =
		hash12(
			piece_cell +
			17.37
		);

	float rnd3 =
		hash12(
			piece_cell +
			91.11
		);


	float delay =
		rnd *
		delay_variation;


	t = clamp(
		(fall_progress - delay) /
		max(
			0.0001,
			1.0 - delay
		),
		0.0,
		1.0
	);


	float center_y =
		point.y /
		grid.y;


	float needed =
		(1.0 - center_y) +
		exit_margin;


	float speed_variance =
		0.6 +
		rnd2 *
		0.8;


	float fall_y =
		needed *
		(t * t) *
		gravity *
		speed_variance;


	float drift_x =
		(rnd2 - 0.5) *
		scatter *
		t;


	piece_offset_uv =
		vec2(
			drift_x,
			fall_y
	);


	piece_angle =
		(rnd3 - 0.5) *
		rotation_amount *
		t;
}


void fragment() {

	vec2 uv =
		SCREEN_UV;


	vec2 grid =
		vec2(
			float(pieces_x),
			float(pieces_y)
		);


	vec2 p_now =
		uv *
		grid;


	vec2 base_cell =
		floor(p_now);


	vec4 result =
		vec4(0.0);


	bool found =
		false;


	float found_edge =
		0.0;


	float found_t =
		0.0;


	// procura qual caco ocupa este pixel.
	for (
		int iy = 0;
		iy < MAX_ROWS;
		iy++
	) {

		if (iy >= pieces_y) {
			break;
		}


		for (
			int dx = -1;
			dx <= 1;
			dx++
		) {

			float cx =
				base_cell.x +
				float(dx);


			if (
				cx < 0.0 ||
				cx >= grid.x
			) {
				continue;
			}


			vec2 cell_id =
				vec2(
					cx,
					float(iy)
				);


			vec2 point =
				cell_point(
					cell_id
				);


			vec2 piece_center_uv =
				point /
				grid;


			float t;

			vec2 offset;

			float angle;


			piece_transform(
				cell_id,
				point,
				grid,
				t,
				offset,
				angle
			);


			vec2 rel_now =
				uv -
				piece_center_uv;


			// exatamente a mesma transformacao
			// do shader original.
			// nao existe expansao aqui.
			vec2 uv_from =
				piece_center_uv +
				rot(-angle) *
				(rel_now - offset);


			if (
				uv_from.x < 0.0 ||
				uv_from.y < 0.0 ||
				uv_from.x > 1.0 ||
				uv_from.y > 1.0
			) {
				continue;
			}


			vec2 p_from =
				uv_from *
				grid;


			vec2 from_cell;

			vec2 from_point;

			float from_edge;


			voronoi_info(
				p_from,
				from_cell,
				from_point,
				from_edge
			);


			// garante que a origem pertence
			// ao mesmo caco.
			if (
				distance(
					from_cell,
					cell_id
				) > 0.001
			) {
				continue;
			}


			// imagem congelada da cena atual.
			result =
				texture(
					current_tex,
					uv_from
				);


			found_edge =
				from_edge;


			found_t =
				t;


			found =
				true;


			break;
		}


		if (found) {
			break;
		}
	}


	// cena nova sendo renderizada ao vivo.
	vec4 fundo =
		texture(
			background_tex,
			uv
		);


	// cena nova ja transformada na cena principal.
	vec4 cena_final =
		texture(
			screen_tex,
			uv
		);


	// faz a troca final de maneira praticamente invisivel.
	fundo =
		mix(
			fundo,
			cena_final,
			final_blend
	);


	// por padrao mostra a cena nova.
	COLOR =
		fundo;


	if (found) {

		float edge =
			1.0 -
			smoothstep(
				0.0,
				edge_thickness,
				found_edge
			);


		result.rgb +=
			edge *
			edge_brightness;


		float fade =
			1.0;


		if (
			alpha_fade_start < 1.0
		) {

			fade =
				1.0 -
				smoothstep(
					alpha_fade_start,
					1.0,
					found_t
				);
		}


		result.a *=
			fade;


		// caco da cena atual sobre a cena nova.
		COLOR =
			mix(
				fundo,
				result,
				result.a
			);
	}


	// protecao especifica para o inicio.
	//
	// enquanto fall_progress for exatamente 0,
	// a tela inteira e a cena atual.
	//
	// isso impede completamente que o point_jitter
	// abra qualquer buraco antes do primeiro movimento.
	float inicio =
		1.0 -
		step(
			0.000001,
			fall_progress
		);


	COLOR =
		mix(
			COLOR,
			texture(
				current_tex,
				uv
			),
			inicio
		);
}