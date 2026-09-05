package main

import "core:testing"

@(test)
parse_args_defaults :: proc(t: ^testing.T) {
	opts, ok := parse_args([]string{"pk"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.command, Command.Show_All)
	testing.expect_value(t, opts.save, false)
}

@(test)
parse_args_each_mode :: proc(t: ^testing.T) {
	cases := []struct {
		args: []string,
		want: Command,
	}{
		{[]string{"pk", "-h"},   .Hidden_Only},
		{[]string{"pk", "-nh"},  .Visible_Only},
		{[]string{"pk", "-f"},   .Folders_Only},
		{[]string{"pk", "-fi"},  .Files_Only},
		{[]string{"pk", "-t"},   .Tree_All},
		{[]string{"pk", "-nht"}, .Tree_Visible},
		{[]string{"pk", "-d"},   .Detail},
	}

	for c in cases {
		opts, ok := parse_args(c.args)
		testing.expect(t, ok)
		testing.expect_value(t, opts.command, c.want)
	}
}

@(test)
parse_args_save :: proc(t: ^testing.T) {
	opts, ok := parse_args([]string{"pk", "-s"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.command, Command.Show_All)
	testing.expect_value(t, opts.save, true)

	opts, ok = parse_args([]string{"pk", "-nht", "-s"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.command, Command.Tree_Visible)
	testing.expect_value(t, opts.save, true)

	opts, ok = parse_args([]string{"pk", "-s", "-d"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.command, Command.Detail)
	testing.expect_value(t, opts.save, true)
}

@(test)
parse_args_rejects_unknown :: proc(t: ^testing.T) {
	_, ok := parse_args([]string{"pk", "-x"})
	testing.expect(t, !ok)
}

@(test)
parse_args_rejects_two_modes :: proc(t: ^testing.T) {
	_, ok := parse_args([]string{"pk", "-h", "-f"})
	testing.expect(t, !ok)
}

@(test)
parse_args_help :: proc(t: ^testing.T) {
	opts, ok := parse_args([]string{"pk", "--help"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.help, true)
	testing.expect_value(t, opts.command, Command.Show_All)
	testing.expect_value(t, opts.save, false)

	opts, ok = parse_args([]string{"pk", "-h"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.help, false)
	testing.expect_value(t, opts.command, Command.Hidden_Only)
}

@(test)
parse_args_path :: proc(t: ^testing.T) {
	opts, ok := parse_args([]string{"pk", "/home/user/docs"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.path, "/home/user/docs")
	testing.expect_value(t, opts.command, Command.Show_All)

	opts, ok = parse_args([]string{"pk", "-d", "/tmp/foo"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.path, "/tmp/foo")
	testing.expect_value(t, opts.command, Command.Detail)

	opts, ok = parse_args([]string{"pk", "-nht", "-s", "some/path"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.path, "some/path")
	testing.expect_value(t, opts.command, Command.Tree_Visible)
	testing.expect_value(t, opts.save, true)

	opts, ok = parse_args([]string{"pk"})
	testing.expect(t, ok)
	testing.expect_value(t, opts.path, ".")

	_, ok = parse_args([]string{"pk", "/a", "/b"})
	testing.expect(t, !ok)
}
