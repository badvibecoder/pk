package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"
import "core:testing"

tree_fixture_dir := "/tmp/pk_tree_fixture"

make_tree_fixture :: proc() {
	os.remove_all(tree_fixture_dir)
	os.make_directory_all(fmt.tprintf("%s/dir1/sub", tree_fixture_dir))
	os.make_directory_all(fmt.tprintf("%s/dir2", tree_fixture_dir))
	os.make_directory_all(fmt.tprintf("%s/.hidden_dir", tree_fixture_dir))
	_ = os.write_entire_file(fmt.tprintf("%s/a.txt", tree_fixture_dir), "x")
	_ = os.write_entire_file(fmt.tprintf("%s/dir1/b.txt", tree_fixture_dir), "x")
	_ = os.write_entire_file(fmt.tprintf("%s/dir1/sub/c.txt", tree_fixture_dir), "x")
	_ = os.write_entire_file(fmt.tprintf("%s/dir2/d.txt", tree_fixture_dir), "x")
	_ = os.write_entire_file(fmt.tprintf("%s/.hidden_dir/e.txt", tree_fixture_dir), "x")
	_ = os.write_entire_file(fmt.tprintf("%s/.hidden_file", tree_fixture_dir), "x")
}

check_tree :: proc(t: ^testing.T, command: Command, want: string) {
	b := strings.builder_make(0, 0)
	defer strings.builder_destroy(&b)

	fd, errno := linux.open(cstring(raw_data(tree_fixture_dir)), {.DIRECTORY, .CLOEXEC})
	testing.expect(t, errno == .NONE)
	defer linux.close(fd)

	walk_tree(&b, fd, "", command, false)
	testing.expect_value(t, strings.to_string(b), want)
}

@(test)
tree_cases :: proc(t: ^testing.T) {
	make_tree_fixture()
	defer os.remove_all(tree_fixture_dir)

	check_tree(t, .Tree_All,
		"├── .hidden_dir\n" +
		"│   └── e.txt\n" +
		"├── dir1\n" +
		"│   ├── sub\n" +
		"│   │   └── c.txt\n" +
		"│   └── b.txt\n" +
		"├── dir2\n" +
		"│   └── d.txt\n" +
		"├── .hidden_file\n" +
		"└── a.txt\n")

	check_tree(t, .Tree_Visible,
		"├── dir1\n" +
		"│   ├── sub\n" +
		"│   │   └── c.txt\n" +
		"│   └── b.txt\n" +
		"├── dir2\n" +
		"│   └── d.txt\n" +
		"└── a.txt\n")
}
