package main

import "core:testing"

@(test)
parse_id_name_cases :: proc(t: ^testing.T) {
	entries := parse_id_name("root:x:0:0:root:/root:/bin/bash\nnobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin\n")
	defer delete(entries)

	testing.expect_value(t, len(entries), 2)
	testing.expect_value(t, entries[0].id, u32(0))
	testing.expect_value(t, entries[0].name, "root")
	testing.expect_value(t, entries[1].id, u32(65534))
	testing.expect_value(t, entries[1].name, "nobody")
}

@(test)
lookup_name_cases :: proc(t: ^testing.T) {
	entries := parse_id_name("root:x:0:0:root:/root:/bin/bash\n")
	defer delete(entries)

	testing.expect_value(t, lookup_name(entries, 0), "root")
	testing.expect_value(t, lookup_name(entries, 12345), "")
}
