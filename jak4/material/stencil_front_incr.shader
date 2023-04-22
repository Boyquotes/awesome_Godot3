shader_type spatial;
render_mode unshaded, depth_test_disable, cull_back, blend_mul;

stencil front {
	test always;
	pass incr;
}