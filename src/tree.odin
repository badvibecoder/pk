package main

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:sys/linux"

tree_output :: proc(b: ^strings.Builder, path: string, command: Command, color: bool) {
	fd := open_dir(path)
	defer linux.close(fd)

	strings.write_string(b, path)
	strings.write_byte(b, '\n')
	walk_tree(b, fd, "", command, color)
}

walk_tree :: proc(b: ^strings.Builder, fd: linux.Fd, prefix: string, command: Command, color: bool) {
	entries, dirents := scan_dir(fd, command)
	slice.sort_by(entries[:], entry_less_tree)
	defer delete(entries)
	defer delete(dirents)

	for entry, i in entries {
		last := i == len(entries) - 1
		strings.write_string(b, prefix)
		if last {
			strings.write_string(b, "└── ")
		} else {
			strings.write_string(b, "├── ")
		}
		write_entry(b, entry, color)
		strings.write_byte(b, '\n')

		if entry.is_dir {
			child, cerrno := linux.openat(fd, cstring(raw_data(entry.name)), {.DIRECTORY, .CLOEXEC})
			if cerrno == .NONE {
				tail := "│   "
				if last {
					tail = "    "
				}
				walk_tree(b, child, fmt.tprintf("%s%s", prefix, tail), command, color)
				linux.close(child)
			}
		}
	}
}
