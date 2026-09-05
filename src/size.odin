package main

import "core:fmt"

human_size :: proc(bytes: u64) -> string {
	kb := bytes / 1024
	if kb < 1024 {
		return fmt.tprintf("%dKB", kb)
	}
	mb := kb / 1024
	if mb < 1024 {
		return fmt.tprintf("%dMB", mb)
	}
	return fmt.tprintf("%dGB", mb / 1024)
}
