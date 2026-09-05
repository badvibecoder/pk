package main

import "core:os"
import "core:strconv"
import "core:strings"

Id_Name :: struct {
	id:   u32,
	name: string,
}

User_Table :: struct {
	users:  []Id_Name,
	groups: []Id_Name,
	passwd: []u8,
	group:  []u8,
}

load_user_table :: proc() -> User_Table {
	table := User_Table{}
	if data, err := os.read_entire_file("/etc/passwd", context.allocator); err == nil {
		table.passwd = data
		table.users = parse_id_name(string(data))
	}
	if data, err := os.read_entire_file("/etc/group", context.allocator); err == nil {
		table.group = data
		table.groups = parse_id_name(string(data))
	}
	return table
}

free_user_table :: proc(table: ^User_Table) {
	delete(table.users)
	delete(table.groups)
	delete(table.passwd)
	delete(table.group)
}

parse_id_name :: proc(text: string) -> []Id_Name {
	entries := make([dynamic]Id_Name)
	for line in strings.split_lines(text, context.temp_allocator) {
		parts := strings.split(line, ":", context.temp_allocator)
		if len(parts) >= 3 {
			if id, ok := strconv.parse_uint(parts[2]); ok {
				append(&entries, Id_Name{id = u32(id), name = parts[0]})
			}
		}
	}
	return entries[:]
}

lookup_name :: proc(entries: []Id_Name, id: u32) -> string {
	for e in entries {
		if e.id == id {
			return e.name
		}
	}
	return ""
}
