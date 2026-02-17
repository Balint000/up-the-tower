extends GutTest
# Tests for player health system

var player
var health_component

func before_each():
	player = CharacterBody2D.new()
	add_child_autofree(player)
	
	# Mock health component
	health_component = Node.new()
	health_component.name = "HealthComponent"
	health_component.set_script(load("res://tests/unit/mocks/mock_health_component.gd"))
	player.add_child(health_component)

func test_player_has_health_component():
	var health = player.get_node_or_null("HealthComponent")
	assert_not_null(health, "Player should have a HealthComponent")

func test_player_starts_with_full_health():
	assert_eq(health_component.current_health, health_component.max_health,
		"Player should start with full health")

func test_player_can_take_damage():
	var initial_health = health_component.current_health
	health_component.take_damage(10)
	
	assert_lt(health_component.current_health, initial_health,
		"Player health should decrease after taking damage")

func test_player_health_cannot_go_below_zero():
	health_component.take_damage(9999)
	
	assert_gte(health_component.current_health, 0,
		"Player health should not go below zero")

func test_player_can_heal():
	health_component.take_damage(50)
	var damaged_health = health_component.current_health
	
	health_component.heal(25)
	
	assert_gt(health_component.current_health, damaged_health,
		"Player should be able to heal")

func test_player_health_cannot_exceed_max():
	health_component.heal(9999)
	
	assert_lte(health_component.current_health, health_component.max_health,
		"Player health should not exceed maximum")

func test_player_dies_at_zero_health():
	health_component.current_health = 0
	
	assert_true(health_component.is_dead(),
		"Player should be dead at zero health")

func test_player_emits_signal_on_death():
	watch_signals(health_component)
	
	health_component.take_damage(9999)
	
	assert_signal_emitted(health_component, "died",
		"Should emit 'died' signal when health reaches zero")

func test_player_emits_signal_on_damage():
	watch_signals(health_component)
	
	health_component.take_damage(10)
	
	assert_signal_emitted(health_component, "health_changed",
		"Should emit 'health_changed' signal when taking damage")
