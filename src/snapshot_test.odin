package main

import "core:strings"
import "core:testing"

@(test)
snapshot_name_format :: proc(t: ^testing.T) {
	name := snapshot_name()
	testing.expect(t, strings.has_prefix(name, "pk-snap-"))
	testing.expect_value(t, len(name), 27)
}
