## This is an example resource simulating a saved game.
class_name SRLSavedGame
extends Resource

## The current health of the player
@export var health:int = 100

## A sub-resource with a property having `path` in its name. This should not be detected as false positive.
@export var sub_resource:SavedGameSubResource = SavedGameSubResource.new()
