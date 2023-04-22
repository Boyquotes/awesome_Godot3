tool
extends Node

export(Color) var sun_light_color setget set_sun_color
export(bool) var sun_visible setget set_sun_visible
export(Color) var indirect_light_color setget set_indirect_light_color
export(Color) var fog_color setget set_fog_color
export(float) var fog_depth_begin setget set_fog_depth_begin
export(float) var fog_depth_end setget set_fog_depth_end
export(Color) var ambient_light_color setget set_ambient_light
export(Color) var background_color setget set_background_color
export(float) var skybox_blend setget set_skybox_blend
export(Texture) var skybox_gradient setget set_skybox_gradient
export(Texture) var skybox_gradient2 setget set_skybox_gradient2
export(Transform) var sun_true_transform setget set_sun_transform

var active_overrides: Array

onready var sun := $"../sun"
onready var vis_sun := $"../sun_true_rotation"
onready var skybox := $"../skybox"
onready var env := $"../WorldEnvironment"

func _init():
	active_overrides = []

func no(override):
	return !(override in active_overrides)

func set_sun_color(sc: Color):
	sun_light_color = sc
	if sun:
		sun.light_color = sc

func set_sun_visible(sv: bool):
	sun_visible = sv
	if sun:
		# Sun is hidden in any environment when it's night
		if no("show_sun") or !sv:
			sun.visible = sv

func set_indirect_light_color(ic: Color):
	indirect_light_color = ic
	if env and no("indirect_light"):
		env.environment.indirect_light_color = ic

func set_fog_color(fc: Color):
	fog_color = fc
	if env and no("custom_fog"):
		env.environment.fog_color = fc

func set_fog_depth_begin(fdb:float):
	fog_depth_begin = fdb
	if env and no("fog_begin"):
		env.environment.fog_depth_begin = fdb

func set_fog_depth_end(fde: float):
	fog_depth_end = fde
	if env and no("fog_end"):
		env.environment.fog_depth_end = fde

func set_ambient_light(abc: Color):
	ambient_light_color = abc
	if env:
		env.environment.ambient_light_color = abc

func set_background_color(bgc: Color):
	background_color = bgc
	if env:
		env.environment.background_color = bgc

func set_skybox_blend(sb: float):
	skybox_blend = sb
	if skybox:
		skybox.get_surface_material(0).set_shader_param("blend", sb)

func set_skybox_gradient(sg:Texture):
	skybox_gradient = sg
	if skybox:
		skybox.get_surface_material(0).set_shader_param("gradient", sg)

func set_skybox_gradient2(sg: Texture):
	skybox_gradient2 = sg
	if skybox:
		skybox.get_surface_material(0).set_shader_param("gradient2", sg)

func set_sun_transform(t: Transform):
	sun_true_transform = t
	if vis_sun:
		vis_sun.transform = t
		if Engine.editor_hint:
			sun.transform = t
