package main

import "core:strings"
import "core:testing"

@(test)
entry_style_cases :: proc(t: ^testing.T) {
	hidden_dir := Entry{name = ".hdir", is_dir = true, is_hidden = true}
	hidden_file := Entry{name = ".hfile", is_dir = false, is_hidden = true}
	dir := Entry{name = "dir", is_dir = true, is_hidden = false}
	file := Entry{name = "file", is_dir = false, is_hidden = false}

	p, s := entry_style(hidden_dir)
	testing.expect_value(t, p, ANSI_BOLD_RED)
	testing.expect_value(t, s, ANSI_RESET)

	p, s = entry_style(hidden_file)
	testing.expect_value(t, p, ANSI_RED)
	testing.expect_value(t, s, ANSI_RESET)

	p, s = entry_style(dir)
	testing.expect_value(t, p, ANSI_BOLD)
	testing.expect_value(t, s, ANSI_RESET)

	p, s = entry_style(file)
	testing.expect_value(t, p, "")
	testing.expect_value(t, s, "")
}

@(test)
flat_output_one_per_line :: proc(t: ^testing.T) {
	entries := []Entry{
		{name = "a"},
		{name = "bb"},
		{name = "ccc"},
	}

	b := strings.builder_make(0, 0)
	defer strings.builder_destroy(&b)
	flat_output(&b, entries, false, 0)
	testing.expect_value(t, strings.to_string(b), "a\nbb\nccc\n")
}

@(test)
flat_output_columns :: proc(t: ^testing.T) {
	entries := []Entry{
		{name = "a"},
		{name = "bb"},
		{name = "ccc"},
	}

	b := strings.builder_make(0, 0)
	defer strings.builder_destroy(&b)
	flat_output(&b, entries, false, 80)
	testing.expect_value(t, strings.to_string(b), "a    bb   ccc\n")
}

@(test)
flat_output_color :: proc(t: ^testing.T) {
	entries := []Entry{
		{name = "dir", is_dir = true},
		{name = ".hidden", is_hidden = true},
		{name = "file"},
	}

	b := strings.builder_make(0, 0)
	defer strings.builder_destroy(&b)
	flat_output(&b, entries, true, 0)

	want := ANSI_BOLD + "dir" + ANSI_RESET + "\n" +
		ANSI_RED + ".hidden" + ANSI_RESET + "\n" +
		"file\n"
	testing.expect_value(t, strings.to_string(b), want)
}
