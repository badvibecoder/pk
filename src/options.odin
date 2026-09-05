package main

Command :: enum {
	Show_All,
	Hidden_Only,
	Visible_Only,
	Folders_Only,
	Files_Only,
	Tree_All,
	Tree_Visible,
	Detail,
}

Options :: struct {
	command: Command,
	save:    bool,
	help:    bool,
	path:    string,
}

options_default :: proc() -> Options {
	return Options{command = .Show_All, path = "."}
}
