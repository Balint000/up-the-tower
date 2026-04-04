extends GutTest

# Very basic smoke tests to check that the test runner works.

func test_truth():
	assert_true(true, "Basic assertion should pass")

func test_basic_math():
	assert_eq(1 + 1, 2, "1 + 1 should equal 2")
