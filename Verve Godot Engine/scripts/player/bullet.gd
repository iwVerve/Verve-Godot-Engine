extends Area2D


var speed := 800.0
var direction := Vector2.RIGHT


func _physics_process(delta):
	global_position += delta * speed * direction


func _on_lifetime_timer_timeout():
	queue_free()


func _on_body_entered(_body):
	queue_free()
