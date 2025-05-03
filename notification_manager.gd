extends Node

# Manages notifications displayed in the Notifications node.
@export var fade_duration: float = 3.0

func add_notification(message: String):
	var notification_label = Label.new()
	notification_label.text = message
	$VBoxContainer.add_child(notification_label)

	var tween: Tween = notification_label.create_tween()
	tween.tween_property(notification_label, "modulate:a", 0, fade_duration)
	tween.finished.connect(func():
		notification_label.queue_free()
	)

	# Store the label to remove it later
	notification_label.set_meta("tween", tween)
