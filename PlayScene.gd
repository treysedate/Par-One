extends Node2D

signal score_points
signal reset_power_meter

export(Array, PackedScene) var courses
export var SHAKE_AMOUNT = 1.0

var currentCourseNumber = 0
var currentCourse: Node2D
var confetti_scene = preload("res://Confetti.tscn")

func _ready():
	self.connect("reset_power_meter", $PowerMeter, "_on_reset_power_meter")
	randomize()
	loadCourse(currentCourseNumber)

func _input(event):
	if event is InputEventKey and event.pressed and event.scancode != KEY_SPACE:
		if (event.scancode - 49 < courses.size()):
			currentCourse.queue_free()
			loadCourse(event.scancode - 49)

func loadNextCourse():
	currentCourseNumber = currentCourseNumber + 1
	if (currentCourseNumber < courses.size()):
		loadCourse(currentCourseNumber)

func loadCourse(courseNumber):
	if (courseNumber < 0 || courseNumber >= courses.size()):
		return
	if (currentCourse != null):
		currentCourse.queue_free()
	emit_signal("reset_power_meter")
	
	currentCourse = courses[courseNumber].instance()
	currentCourse.set_global_transform($ScreenCenter.get_global_transform())
	add_child(currentCourse)
	
	var golfBall: Node2D = currentCourse.get_node("GolfBall")
	var hole: Node2D = currentCourse.get_node("Hole")
	
	golfBall.connect("golf_ball_hit", $PowerMeter, "_on_golf_ball_hit")
	golfBall.connect("golf_ball_stopped", self, "_on_golf_ball_stopped")
	golfBall.connect("screen_shake", $ScreenShake, "_on_screen_shake")
	$PowerMeter.connect("power_level_selected", golfBall, "_on_power_level_selected")
	
	$Timer/Timer.connect("timeout", self, "_on_timeout")
	$CelebrationTimer.connect("timeout", self, "_on_celebration_timeout")
	hole.connect("hole_in_one", golfBall, "_on_hole_in_one")
	hole.connect("hole_in_one", self, "_on_hole_in_one")
	
	self.connect("score_points", $HighScore, "_on_score_points")
	golfBall.connect("score_points", $HighScore, "_on_score_points")
	hole.connect("score_points", $HighScore, "_on_score_points")
	
	currentCourse.find_node("GolfBall").add_to_group("golfBall")

func _on_celebration_timeout():
	loadNextCourse()

func _on_golf_ball_stopped():
	calculate_score()
	loadNextCourse()

func _on_timeout():
	calculate_score()
	loadNextCourse()

func _on_hole_in_one():
	$CelebrationTimer.start()
	var confetti = confetti_scene.instance()
	confetti.set_global_position(currentCourse.get_node("Hole").get_global_position())
	add_child(confetti)

func calculate_score():
	if ($GolfBall == null):
		return
	var golfBallPosition = $GolfBall/CollisionShape2D.get_global_transform().get_origin()
	var holePosition = $Hole.get_global_transform().get_origin()
	var distance = golfBallPosition.distance_to(holePosition)
	emit_signal("score_points", floor(distance))