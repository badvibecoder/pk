package main

import "core:fmt"
import "core:strings"
import "core:sys/linux"
import "core:time"

Detail :: struct {
	name:      string,
	is_dir:    bool,
	is_hidden: bool,
	mode:      linux.Mode,
	nlink:     uint,
	uid:       linux.Uid,
	gid:       linux.Gid,
	size:      u64,
	mtime:     linux.Time_Spec,
}

detail_from_entry :: proc(entry: Entry, dirfd: linux.Fd) -> Detail {
	d := Detail{
		name      = entry.name,
		is_dir    = entry.is_dir,
		is_hidden = entry.is_hidden,
	}
	st: linux.Stat
	if linux.fstatat(dirfd, cstring(raw_data(entry.name)), &st, {.SYMLINK_NOFOLLOW}) == .NONE {
		d.mode = st.mode
		d.nlink = st.nlink
		d.uid = st.uid
		d.gid = st.gid
		d.size = u64(st.size)
		d.mtime = st.mtime
	}
	return d
}

mode_string :: proc(mode: linux.Mode) -> [10]u8 {
	s: [10]u8
	s[0] = '-'
	if linux.S_ISDIR(mode) {
		s[0] = 'd'
	} else if linux.S_ISLNK(mode) {
		s[0] = 'l'
	} else if linux.S_ISCHR(mode) {
		s[0] = 'c'
	} else if linux.S_ISBLK(mode) {
		s[0] = 'b'
	} else if linux.S_ISFIFO(mode) {
		s[0] = 'p'
	} else if linux.S_ISSOCK(mode) {
		s[0] = 's'
	}
	write_perm3(s[1:4], mode, .IRUSR, .IWUSR, .IXUSR, .ISUID, 's')
	write_perm3(s[4:7], mode, .IRGRP, .IWGRP, .IXGRP, .ISGID, 's')
	write_perm3(s[7:10], mode, .IROTH, .IWOTH, .IXOTH, .ISVTX, 't')
	return s
}

write_perm3 :: proc(s: []u8, mode: linux.Mode, r, w, x, special: linux.Mode_Bits, sc: byte) {
	if r in mode {
		s[0] = 'r'
	} else {
		s[0] = '-'
	}
	if w in mode {
		s[1] = 'w'
	} else {
		s[1] = '-'
	}
	if special in mode {
		if x in mode {
			s[2] = sc
		} else {
			s[2] = sc - 32
		}
	} else if x in mode {
		s[2] = 'x'
	} else {
		s[2] = '-'
	}
}

MONTH_ABBR := [?]string{"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
SIX_MONTHS :: i64(6 * 30 * 24 * 60 * 60)

write_mtime :: proc(b: ^strings.Builder, ts: linux.Time_Spec, now_unix: i64) {
	tm := local_parts(i64(ts.time_sec))
	strings.write_string(b, MONTH_ABBR[tm.mon + 1])
	strings.write_byte(b, ' ')
	if tm.mday < 10 {
		strings.write_byte(b, ' ')
	}
	fmt.sbprint(b, tm.mday)

	age := now_unix - i64(ts.time_sec)
	if age < SIX_MONTHS && age > -3600 {
		strings.write_byte(b, ' ')
		fmt.sbprintf(b, "%02d:%02d", tm.hour, tm.min)
	} else {
		strings.write_string(b, "  ")
		fmt.sbprint(b, tm.year + 1900)
	}
}

int_digits :: proc(n: u64) -> int {
	n := n
	d := 1
	for n >= 10 {
		n /= 10
		d += 1
	}
	return d
}

write_pad_uint :: proc(b: ^strings.Builder, n: u64, width: int) {
	for _ in 0 ..< width - int_digits(n) {
		strings.write_byte(b, ' ')
	}
	fmt.sbprint(b, n)
}

write_pad_str :: proc(b: ^strings.Builder, s: string, width: int) {
	for _ in 0 ..< width - len(s) {
		strings.write_byte(b, ' ')
	}
	strings.write_string(b, s)
}

write_pad_left :: proc(b: ^strings.Builder, s: string, width: int) {
	strings.write_string(b, s)
	for _ in 0 ..< width - len(s) {
		strings.write_byte(b, ' ')
	}
}

owner_name :: proc(users: []Id_Name, uid: u32) -> string {
	if name := lookup_name(users, uid); name != "" {
		return name
	}
	return fmt.tprintf("%d", uid)
}

group_name :: proc(groups: []Id_Name, gid: u32) -> string {
	if name := lookup_name(groups, gid); name != "" {
		return name
	}
	return fmt.tprintf("%d", gid)
}

detail_output :: proc(b: ^strings.Builder, details: []Detail, dirfd: linux.Fd, users: []Id_Name, groups: []Id_Name, color: bool) {
	if len(details) == 0 {
		return
	}

	sizes := make([]string, len(details))
	owners := make([]string, len(details))
	group_strs := make([]string, len(details))
	defer delete(sizes)
	defer delete(owners)
	defer delete(group_strs)

	nlink_w, owner_w, group_w, size_w := 0, 0, 0, 0
	for d, i in details {
		sizes[i] = human_size(d.size)
		owners[i] = owner_name(users, u32(d.uid))
		group_strs[i] = group_name(groups, u32(d.gid))
		nlink_w = max(nlink_w, int_digits(u64(d.nlink)))
		owner_w = max(owner_w, len(owners[i]))
		group_w = max(group_w, len(group_strs[i]))
		size_w = max(size_w, len(sizes[i]))
	}

	now_unix := time.time_to_unix(time.now())

	for d, i in details {
		ms := mode_string(d.mode)
		strings.write_string(b, string(ms[:]))
		strings.write_byte(b, ' ')
		write_pad_uint(b, u64(d.nlink), nlink_w)
		strings.write_byte(b, ' ')
		write_pad_left(b, owners[i], owner_w)
		strings.write_byte(b, ' ')
		write_pad_left(b, group_strs[i], group_w)
		strings.write_byte(b, ' ')
		write_pad_str(b, sizes[i], size_w)
		strings.write_byte(b, ' ')
		write_mtime(b, d.mtime, now_unix)
		strings.write_byte(b, ' ')
		write_entry(b, Entry{name = d.name, is_dir = d.is_dir, is_hidden = d.is_hidden}, color)
		if linux.S_ISLNK(d.mode) {
			buf: [4096]u8
			if n, errno := linux.readlinkat(dirfd, cstring(raw_data(d.name)), buf[:]); errno == .NONE {
				strings.write_string(b, " -> ")
				strings.write_string(b, string(buf[:n]))
			}
		}
		strings.write_byte(b, '\n')
	}
}
