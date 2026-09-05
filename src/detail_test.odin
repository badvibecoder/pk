package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"
import "core:testing"

@(test)
mode_string_cases :: proc(t: ^testing.T) {
	ms := mode_string(linux.Mode{.IFDIR, .IRUSR, .IWUSR, .IXUSR, .IRGRP, .IXGRP, .IROTH, .IXOTH})
	testing.expect_value(t, string(ms[:]), "drwxr-xr-x")

	ms = mode_string(linux.Mode{.IFREG, .IRUSR, .IWUSR, .IRGRP, .IROTH})
	testing.expect_value(t, string(ms[:]), "-rw-r--r--")

	ms = mode_string(linux.Mode{.IFREG, .ISUID, .IRUSR, .IWUSR, .IXUSR, .IRGRP, .IXGRP, .IROTH, .IXOTH})
	testing.expect_value(t, string(ms[:]), "-rwsr-xr-x")

	ms = mode_string(linux.S_IFLNK | linux.Mode{.IRUSR, .IWUSR, .IXUSR, .IRGRP, .IWGRP, .IXGRP, .IROTH, .IWOTH, .IXOTH})
	testing.expect_value(t, string(ms[:]), "lrwxrwxrwx")

	ms = mode_string(linux.Mode{.IFDIR, .ISVTX, .IRUSR, .IWUSR, .IXUSR, .IRGRP, .IWGRP, .IXGRP, .IROTH, .IWOTH, .IXOTH})
	testing.expect_value(t, string(ms[:]), "drwxrwxrwt")
}

@(test)
local_parts_sanity :: proc(t: ^testing.T) {
	tm := local_parts(0)
	testing.expect(t, tm.year == 69 || tm.year == 70)
	testing.expect(t, tm.mon >= 0 && tm.mon <= 11)
	testing.expect(t, tm.mday >= 1 && tm.mday <= 31)
	testing.expect(t, tm.hour >= 0 && tm.hour < 24)
	testing.expect(t, tm.min >= 0 && tm.min < 60)
	testing.expect(t, tm.sec >= 0 && tm.sec < 60)
}

@(test)
mtime_format_length :: proc(t: ^testing.T) {
	b := strings.builder_make(0, 16)
	defer strings.builder_destroy(&b)
	write_mtime(&b, linux.Time_Spec{time_sec = 0, time_nsec = 0}, SIX_MONTHS + 1)
	testing.expect_value(t, len(strings.to_string(b)), 12)
}

@(test)
detail_from_entry_dirfd :: proc(t: ^testing.T) {
	dir := "/tmp/pk_detail_fixture"
	os.remove_all(dir)
	os.make_directory_all(dir)
	defer os.remove_all(dir)

	_ = os.write_entire_file(fmt.tprintf("%s/file", dir), "hello")

	fd := open_dir(dir)
	defer linux.close(fd)

	d := detail_from_entry(Entry{name = "file"}, fd)
	testing.expect_value(t, d.size, u64(5))
	testing.expect(t, linux.S_ISREG(d.mode))
}
