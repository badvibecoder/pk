package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"

main :: proc() {
	timing_begin("parse")
	opts, ok := parse_args(os.args)
	timing_end()

	if !ok {
		print_usage()
		os.exit(2)
	}

	if opts.help {
		print_help()
		return
	}

	width, is_tty := terminal_width()

	b := strings.builder_make(0, 16 * 1024)
	defer strings.builder_destroy(&b)

	if opts.command == .Tree_All || opts.command == .Tree_Visible {
		timing_begin("tree")
		tree_output(&b, opts.path, opts.command, is_tty)
		timing_end()
	} else {
		listing := read_listing(opts.path, opts.command)
		defer free_listing(&listing)

		if opts.command == .Detail {
			fd := open_dir(opts.path)
			defer linux.close(fd)

			timing_begin("stat")
			details := make([]Detail, len(listing.entries))
			defer delete(details)
			for entry, i in listing.entries[:] {
				details[i] = detail_from_entry(entry, fd)
			}
			timing_end()

			timing_begin("users")
			table := load_user_table()
			timing_end()
			defer free_user_table(&table)

			timing_begin("format")
			detail_output(&b, details, fd, table.users, table.groups, is_tty)
			timing_end()
		} else {
			timing_begin("format")
			flat_output(&b, listing.entries[:], is_tty, width)
			timing_end()
		}
	}

	timing_begin("write")
	if opts.save {
		name := snapshot_name()
		if err := os.write_entire_file(name, strings.to_string(b)); err != nil {
			fmt.eprintfln("pk: write '%s': %s", name, err)
			os.exit(1)
		}
	} else {
		os.write_string(os.stdout, strings.to_string(b))
	}
	timing_end()

	timing_report()
}
