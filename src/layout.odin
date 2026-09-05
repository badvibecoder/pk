package main

import "core:strings"

flat_output :: proc(b: ^strings.Builder, entries: []Entry, color: bool, width: int) {
	if len(entries) == 0 {
		return
	}

	if width <= 0 {
		for entry in entries {
			write_entry(b, entry, color)
			strings.write_byte(b, '\n')
		}
		return
	}

	col_width := max_name_len(entries) + 2
	cols := min(width / col_width, len(entries))
	if cols < 1 {
		cols = 1
	}
	rows := (len(entries) + cols - 1) / cols

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			idx := col * rows + row
			if idx >= len(entries) {
				continue
			}
			write_entry(b, entries[idx], color)
			if idx + rows < len(entries) {
				for _ in 0 ..< col_width - len(entries[idx].name) {
					strings.write_byte(b, ' ')
				}
			}
		}
		strings.write_byte(b, '\n')
	}
}

max_name_len :: proc(entries: []Entry) -> int {
	m := 0
	for entry in entries {
		m = max(m, len(entry.name))
	}
	return m
}

write_entry :: proc(b: ^strings.Builder, entry: Entry, color: bool) {
	if !color {
		strings.write_string(b, entry.name)
		return
	}
	prefix, suffix := entry_style(entry)
	strings.write_string(b, prefix)
	strings.write_string(b, entry.name)
	strings.write_string(b, suffix)
}
