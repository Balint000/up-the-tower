extends GutTest

func test_assert_true():
	assert_true(true, "Ez mindig igaz kell legyen")

func test_math():
	assert_eq(1 + 1, 2, "A matematika még működik")
