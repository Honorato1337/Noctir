extends Control
const Vehicles = preload("res://scripts/expedition_vehicles.gd")
const Vfx = preload("res://scripts/pixel_effects.gd")
const Terrain = preload("res://scripts/planet_terrain.gd")
var game: Node2D
func _process(_delta: float) -> void:
	queue_redraw()
func centered(text: String, y: float, font_size: int, color: Color) -> void:
	var width: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(game.font, Vector2((size.x-width)*0.5,y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
func draw_rover_trip(progress: float) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),game.planet().floor)
	Terrain.draw_floor(self,Rect2(Vector2.ZERO,size),game.planet_index)
	for i in 12:
		var point := Vector2(fposmod(i*193.0-progress*190,size.x+160)-80, 230+fposmod(i*117.0,330))
		if absf(point.y-size.y*0.5) < 95: continue
		Terrain.draw_rock(self,Rect2(point,Vector2.ONE*64),game.planet_index,i)
	var vehicle := Vector2(lerpf(-120,size.x+120,smoothstep(0,1,progress)),size.y*0.52)
	for x in range(0,int(clampf(vehicle.x,0,size.x)),18):
		for y: float in [vehicle.y+52,vehicle.y+64]:
			draw_rect(Rect2(x,y,8,2),Color(0.02,0.025,0.05,0.35))
	draw_rect(Rect2(vehicle+Vector2(-70,55),Vector2(140,12)),Color(0.02,0.025,0.05,0.4))
	for i in 7:
		var offset := Vector2(-85-i*13,45+sin(i*1.7+progress*12)*8)
		Vfx.draw_particle(self,vehicle+offset,Vector2.ONE*32,1,(i+int(game.travel_clock*9))%4,Color(1,1,1,(1-i/7.0)*0.7))
	Vehicles.draw_vehicle(self,"rover",vehicle,Vector2.ONE*256,int(game.travel_clock*12)%2)
func block_planet(center: Vector2, radius: int, color: Color) -> void:
	for y in range(-radius,radius,8):
		var half := floorf(sqrt(maxf(0,radius*radius-y*y))/8)*8
		draw_rect(Rect2(center+Vector2(-half,y),Vector2(half*2,8)),color.darkened(0.15 if posmod(y,32)<16 else 0))
func draw_rocket_trip(progress: float) -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("070b19"))
	for i in 65:
		var at := Vector2(fposmod(i*173.0,size.x),fposmod(i*97.0+progress*360,size.y))
		draw_rect(Rect2(at.snapped(Vector2.ONE*4),Vector2.ONE*(2 if i%4 else 4)),Color("6b74b2"))
	block_planet(Vector2(170,size.y-90+progress*180),96,game.planet().floor.lightened(0.15))
	var destination: int = mini(game.room+1,game.total_rooms()-1)
	var target: Color = game.Planets.DATA[destination/game.ARENAS_PER_PLANET].floor.lightened(0.2)
	block_planet(Vector2(size.x-170,50+progress*70),64,target)
	var rocket := rocket_position(progress)
	for i in 9:
		Vfx.draw_particle(self,rocket+Vector2(sin(i*2.3)*6,108+i*12),Vector2.ONE*32,3,(int(game.travel_clock*10)+i)%4,Color(1,1,1,(1-i/9.0)*0.75))
	Vehicles.draw_vehicle(self,"rocket",rocket,Vector2.ONE*256,int(game.travel_clock*10)%2)
func _draw() -> void:
	if not is_instance_valid(game): return
	var progress: float = clampf(game.travel_clock/game.TRAVEL_DURATION,0,1)
	if game.travel_kind == "rover": draw_rover_trip(progress)
	else: draw_rocket_trip(progress)
	draw_rect(Rect2(0,48,size.x,124),Color(0.025,0.035,0.07,0.93))
	centered("TRAVESSIA DE " + game.planet().name if game.travel_kind == "rover" else "VIAGEM INTERPLANETÁRIA",102,32,Color("c1d9f2"))
	var destination: int = mini(game.room+1,game.total_rooms()-1)
	var route: String = "ROVER / ARENA %02d > %02d" % [game.room+1,destination+1]
	if game.travel_kind == "rocket":
		route = "%s > %s / FOGUETE" % [game.planet().name,game.Planets.DATA[destination/game.ARENAS_PER_PLANET].name]
	if game.room == game.total_rooms()-1: route = "EXPEDIÇÃO CONCLUÍDA / RETORNO À ÓRBITA"
	centered(route,142,22,Color("909edd"))
	var bar := Rect2(Vector2(size.x*0.5-200,size.y-110),Vector2(400,8))
	draw_rect(Rect2(bar.position-Vector2(12,12),Vector2(424,78)),Color(0.025,0.035,0.07,0.95))
	draw_rect(bar,Color("12173d"))
	draw_rect(Rect2(bar.position,Vector2(floorf(bar.size.x*progress/4)*4,bar.size.y)),Color("909edd"))
	centered("PERCURSO TERRESTRE" if game.travel_kind == "rover" else "TRANSFERÊNCIA ORBITAL",size.y-64,22,Color("c1d9f2"))

func rocket_position(progress: float) -> Vector2:
	# Ignite in view, then accelerate upward without jumping at the first frame.
	var ascent := clampf((progress-0.18)/0.82,0,1)
	return Vector2(size.x*0.5,lerpf(size.y*0.64,-180,ascent*ascent))
