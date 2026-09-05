package main

import "core:sys/linux"

Winsize :: struct {
	row:    u16,
	col:    u16,
	xpixel: u16,
	ypixel: u16,
}

ANSI_RESET    :: "\x1b[0m"
ANSI_BOLD     :: "\x1b[1m"
ANSI_RED      :: "\x1b[31m"
ANSI_BOLD_RED :: "\x1b[1;31m"

terminal_width :: proc() -> (int, bool) {
	ws: Winsize
	ret := linux.ioctl(linux.Fd(1), linux.TIOCGWINSZ, uintptr(&ws))
	if ret != 0 {
		return 0, false
	}
	return int(ws.col), true
}

entry_style :: proc(entry: Entry) -> (string, string) {
	if entry.is_hidden && entry.is_dir {
		return ANSI_BOLD_RED, ANSI_RESET
	}
	if entry.is_hidden {
		return ANSI_RED, ANSI_RESET
	}
	if entry.is_dir {
		return ANSI_BOLD, ANSI_RESET
	}
	return "", ""
}
