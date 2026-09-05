package main

tm_local :: struct {
	sec: i32, min: i32, hour: i32, mday: i32, mon: i32, year: i32,
	wday: i32, yday: i32, isdst: i32, gmtoff: i64, zone: cstring,
}

foreign import libc "system:c"

@(default_calling_convention = "c")
foreign libc {
	localtime_r :: proc(timer: ^i64, result: ^tm_local) -> ^tm_local ---
}

local_parts :: proc(sec: i64) -> tm_local {
	sec := sec
	tm: tm_local
	localtime_r(&sec, &tm)
	return tm
}
