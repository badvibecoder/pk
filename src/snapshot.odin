package main

import "core:fmt"
import "core:time"

snapshot_name :: proc() -> string {
	t := time.now()
	hour, min, sec := time.clock_from_time(t)
	return fmt.tprintf("pk-snap-%04d-%02d-%02d_%02d-%02d-%02d",
		time.year(t), int(time.month(t)), time.day(t), hour, min, sec)
}
