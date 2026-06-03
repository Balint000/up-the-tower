## @file test_smoke.gd
## @brief Smoke tests that verify the GUT test runner itself is functional.
##
## These tests contain no game logic. They exist only to confirm that
## the test infrastructure is set up correctly and assertions work as expected.
## If any smoke test fails, the test runner itself is broken.
extends GutTest


## @brief Asserts that boolean true is truthy.
## This is the most basic sanity check possible.
func test_truth() -> void:
	assert_true(true, "Basic assertion should pass")


## @brief Asserts that integer addition produces the correct result.
func test_basic_math() -> void:
	assert_eq(1 + 1, 2, "1 + 1 should equal 2")


## @brief Asserts that string concatenation works as expected.
func test_string_concat() -> void:
	assert_eq("hello" + " world", "hello world",
		"String concatenation should produce 'hello world'")
