package main

import "core:testing"

@(test)
human_size_cases :: proc(t: ^testing.T) {
	testing.expect_value(t, human_size(0), "0KB")
	testing.expect_value(t, human_size(500), "0KB")
	testing.expect_value(t, human_size(1024), "1KB")
	testing.expect_value(t, human_size(234 * 1024), "234KB")
	testing.expect_value(t, human_size(1024 * 1024), "1MB")
	testing.expect_value(t, human_size(234 * 1024 * 1024), "234MB")
	testing.expect_value(t, human_size(1024 * 1024 * 1024), "1GB")
	testing.expect_value(t, human_size(2 * 1024 * 1024 * 1024), "2GB")
}
