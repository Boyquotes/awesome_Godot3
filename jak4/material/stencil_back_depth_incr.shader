shader_type spatial;
render_mode unshaded, cull_front, blend_mul;

stencil back {
	test always;
	pass incr;
}