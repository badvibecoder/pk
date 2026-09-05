package main

import "core:fmt"

help_text := `pk — peek, a fast ls

usage: pk [MODE] [PATH] [-s]

modes:
  (none)      list all entries (hidden and visible)
  -h          hidden entries only
  -nh         visible (non-hidden) entries only
  -f          folders only, including hidden
  -fi         files only, including hidden
  -t          tree of all entries, including hidden
  -nht        tree of visible entries only
  -d          details, like ls -al with human sizes

path:
  PATH        directory to list (defaults to the current directory)

output:
  -s          write to pk-snap-<datetime> instead of stdout

help:
  --help      show this help

styling (on a terminal):
  folders     bold
  hidden      red
  hidden dir  bold red
`

command_from_arg :: proc(arg: string) -> (Command, bool) {
	switch arg {
	case "-h":   return .Hidden_Only, true
	case "-nh":  return .Visible_Only, true
	case "-f":   return .Folders_Only, true
	case "-fi":  return .Files_Only, true
	case "-t":   return .Tree_All, true
	case "-nht": return .Tree_Visible, true
	case "-d":   return .Detail, true
	}
	return .Show_All, false
}

parse_args :: proc(args: []string) -> (Options, bool) {
	opts := options_default()
	mode_set := false
	path_set := false

	for arg in args[1:] {
		if command, ok := command_from_arg(arg); ok {
			if mode_set {
				return Options{}, false
			}
			opts.command = command
			mode_set = true
		} else if arg == "-s" {
			opts.save = true
		} else if arg == "--help" {
			opts.help = true
		} else if len(arg) > 0 && arg[0] == '-' {
			return Options{}, false
		} else {
			if path_set {
				return Options{}, false
			}
			opts.path = arg
			path_set = true
		}
	}

	return opts, true
}

print_help :: proc() {
	fmt.print(help_text)
}

print_usage :: proc() {
	fmt.eprint(help_text)
}
