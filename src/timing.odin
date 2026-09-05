package main

import "core:fmt"
import "core:os"
import "core:time"

Timing_Record :: struct {
	name: string,
	ms:   f64,
}

Timing_Active :: struct {
	name:  string,
	start: time.Tick,
}

timing_active: [64]Timing_Active
timing_active_len: int
timing_records: [64]Timing_Record
timing_records_len: int

timing_begin :: proc(name: string) {
	timing_active[timing_active_len] = Timing_Active{name = name, start = time.tick_now()}
	timing_active_len += 1
}

timing_end :: proc() {
	if timing_active_len == 0 {
		return
	}
	timing_active_len -= 1
	active := timing_active[timing_active_len]
	timing_records[timing_records_len] = Timing_Record{
		name = active.name,
		ms   = time.duration_milliseconds(time.tick_since(active.start)),
	}
	timing_records_len += 1
}

timing_report :: proc() {
	buf: [8]u8
	if os.get_env(buf[:], "PK_TIME") == "" {
		return
	}
	for i in 0 ..< timing_records_len {
		fmt.eprintfln("%-12s %.3f ms", timing_records[i].name, timing_records[i].ms)
	}
}
