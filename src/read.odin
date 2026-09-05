package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"

Entry :: struct {
	name:      string,
	is_dir:    bool,
	is_hidden: bool,
}

Listing :: struct {
	entries: [dynamic]Entry,
	dirents: [dynamic]u8,
}

entry_is_hidden :: proc(name: string) -> bool {
	return len(name) > 0 && name[0] == '.'
}

entry_matches :: proc(entry: Entry, command: Command) -> bool {
	keep := true
	switch command {
	case .Hidden_Only:
		keep = entry.is_hidden
	case .Visible_Only, .Tree_Visible:
		keep = !entry.is_hidden
	case .Folders_Only:
		keep = entry.is_dir
	case .Files_Only:
		keep = !entry.is_dir
	case .Show_All, .Tree_All, .Detail:
		keep = true
	}
	return keep
}

free_listing :: proc(listing: ^Listing) {
	delete(listing.entries)
	delete(listing.dirents)
}

scan_dir :: proc(fd: linux.Fd, command: Command) -> (entries: [dynamic]Entry, dirents: [dynamic]u8) {
	buf: [32 * 1024]u8
	for {
		written, errno := linux.getdents(fd, buf[:])
		if errno != .NONE || written == 0 {
			break
		}
		append(&dirents, ..buf[:written])
	}

	offset := 0
	for d in linux.dirent_iterate_buf(dirents[:], &offset) {
		name := linux.dirent_name(d)
		if name == "." || name == ".." {
			continue
		}
		entry := Entry{
			name      = name,
			is_dir    = d.type == .DIR,
			is_hidden = entry_is_hidden(name),
		}
		if entry_matches(entry, command) {
			append(&entries, entry)
		}
	}
	return
}

open_dir :: proc(path: string) -> linux.Fd {
	cpath := strings.clone_to_cstring(path)
	defer delete(cpath)

	fd, errno := linux.open(cpath, {.DIRECTORY, .CLOEXEC})
	if errno != .NONE {
		fmt.eprintfln("pk: open '%s': %s", path, errno)
		os.exit(1)
	}
	return fd
}

read_listing :: proc(path: string, command: Command) -> Listing {
	timing_begin("read")

	fd := open_dir(path)
	defer linux.close(fd)

	entries, dirents := scan_dir(fd, command)
	timing_end()

	timing_begin("sort")
	sort_entries(entries[:])
	timing_end()

	return Listing{entries = entries, dirents = dirents}
}
