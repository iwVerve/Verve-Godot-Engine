extends Area2D


@onready var sprite = $Sprite2D
@onready var respawn_timer = $RespawnTimer


func collect(player: Player):
	if player != null:
		player.refresh_jumps(1)
	
	sprite.hide()
	set_deferred("monitoring", false)
	respawn_timer.start()


func _on_body_entered(body):
	collect(body)


func _on_respawn_timer_timeout():
	sprite.show()
	set_deferred("monitoring", true)
