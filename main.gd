extends Node3D

# there seems to be a race condition when multiplayer physics is enabled.
# running this project, it should eventually stall (v4.7.2.stable.official [ed1daf0bf])

# test runs 

# v4.7.2 DIRECT_STATE=false, multithreaded physics=true:
# run 1: frame ~14300
# run 2: frame ~4500
# run 3: frame ~100

# v4.7.2 DIRECT_STATE=true, multithreaded physics=false
# run 1: reached FRAME_LIMIT without stall
# run 2:  reached FRAME_LIMIT without stall
# run 3: reached FRAME_LIMIT without stall

# v4.7.2  direct_state=false, multithreaded physics=false
#1 reached FRAME_LIMIT without stall
#2 reached FRAME_LIMIT without stall
#3 reached FRAME_LIMIT without stall

# 4.6.stable  DIRECT_STATE false, multithreaded true
#1 reached FRAME_LIMIT without stall
#2 reached FRAME_LIMIT without stall
#3 reached FRAME_LIMIT without stall

const DIRECT_STATE := false

const FRAME_LIMIT := 50000 #hopefully stalls before this

class TorqueBody extends RigidBody3D:

	# if direct_State is set to true to modify PhysicsDirectBodyState3D directly
	# we no longer get stalls

	var calls := 0

	func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
		calls += 1
		if DIRECT_STATE:
			state.apply_torque(Vector3(0.1, 0.2, 0.3))
		else:
			apply_torque(Vector3(0.1, 0.2, 0.3))

var body := TorqueBody.new()
var frame := 0

func _ready() -> void:
	body.gravity_scale = 0 	# no idea if this is needed, 
							# but it keeps the body in place
							# to let it spin.
	body.can_sleep = false
	var collider := CollisionShape3D.new()
	collider.shape = SphereShape3D.new()
	body.add_child(collider)
	add_child(body)
	print("START engine=", Engine.get_version_info(),
		" threaded=", ProjectSettings.get_setting("physics/3d/run_on_separate_thread"),
		" direct_state=", DIRECT_STATE,
		" schedule=", OS.get_environment("GODOT_TORQUE_RACE"))

func _physics_process(_delta: float) -> void:
	frame += 1

	if frame % 100 == 0:
		print("HEARTBEAT frame=", frame, " callbacks=", body.calls)
	if frame >= FRAME_LIMIT:
		print("DONE frames=", frame, " callbacks=", body.calls,
			" angular_velocity=", body.angular_velocity)
		get_tree().quit(0 if body.calls > 0 else 1)
