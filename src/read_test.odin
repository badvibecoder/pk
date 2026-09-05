package main

import "core:fmt"
import "core:os"
import "core:testing"

fixture_dir := "/tmp/pk_read_fixture"

join_path :: proc(name: string) -> string {
	return fmt.tprintf("%s/%s", fixture_dir, name)
}

make_fixture :: proc() {
	os.remove_all(fixture_dir)
	os.make_directory_all(fixture_dir)
	_ = os.write_entire_file(join_path("apple"), "x")
	_ = os.write_entire_file(join_path("Banana"), "x")
	_ = os.write_entire_file(join_path("cherry"), "x")
	_ = os.write_entire_file(join_path(".hidden_file"), "x")
	os.make_directory(join_path("dir_one"))
	os.make_directory(join_path("dir_two"))
	os.make_directory(join_path(".hidden_dir"))
}

expect_names :: proc(t: ^testing.T, entries: []Entry, want: []string) {
	testing.expect_value(t, len(entries), len(want))
	n := min(len(entries), len(want))
	for i in 0 ..< n {
		testing.expect_value(t, entries[i].name, want[i])
	}
}

@(test)
entry_is_hidden_cases :: proc(t: ^testing.T) {
	testing.expect(t, entry_is_hidden(".foo"))
	testing.expect(t, entry_is_hidden("."))
	testing.expect(t, !entry_is_hidden("foo"))
	testing.expect(t, !entry_is_hidden(""))
	testing.expect(t, !entry_is_hidden("dir.name"))
}

@(test)
entry_matches_cases :: proc(t: ^testing.T) {
	hidden_dir := Entry{name = ".hdir", is_dir = true, is_hidden = true}
	hidden_file := Entry{name = ".hfile", is_dir = false, is_hidden = true}
	vis_dir := Entry{name = "dir", is_dir = true, is_hidden = false}
	vis_file := Entry{name = "file", is_dir = false, is_hidden = false}

	testing.expect(t, entry_matches(hidden_dir, .Show_All))
	testing.expect(t, entry_matches(hidden_dir, .Hidden_Only))
	testing.expect(t, !entry_matches(hidden_dir, .Visible_Only))
	testing.expect(t, entry_matches(hidden_dir, .Folders_Only))
	testing.expect(t, !entry_matches(hidden_dir, .Files_Only))
	testing.expect(t, entry_matches(hidden_dir, .Tree_All))
	testing.expect(t, !entry_matches(hidden_dir, .Tree_Visible))
	testing.expect(t, entry_matches(hidden_dir, .Detail))

	testing.expect(t, entry_matches(vis_file, .Show_All))
	testing.expect(t, !entry_matches(vis_file, .Hidden_Only))
	testing.expect(t, entry_matches(vis_file, .Visible_Only))
	testing.expect(t, !entry_matches(vis_file, .Folders_Only))
	testing.expect(t, entry_matches(vis_file, .Files_Only))
}

@(test)
sort_entries_order :: proc(t: ^testing.T) {
	entries := []Entry{
		{name = "cherry"},
		{name = "apple"},
		{name = "Banana"},
		{name = ".hidden"},
	}
	sort_entries(entries)
	expect_names(t, entries, []string{".hidden", "Banana", "apple", "cherry"})
}

@(test)
sort_entries_large :: proc(t: ^testing.T) {
	n := 2000
	entries := make([]Entry, n)
	defer delete(entries)
	for i in 0..<n {
		entries[i] = Entry{name = fmt.tprintf("n%04d", (i * 73) % n)}
	}
	sort_entries(entries)
	for i in 1..<n {
		testing.expect(t, !entry_less(entries[i], entries[i-1]))
	}
}

@(test)
read_listing_filters_and_sorts :: proc(t: ^testing.T) {
	make_fixture()
	defer os.remove_all(fixture_dir)

	all := read_listing(fixture_dir, .Show_All)
	defer free_listing(&all)
	expect_names(t, all.entries[:], []string{".hidden_dir", ".hidden_file", "Banana", "apple", "cherry", "dir_one", "dir_two"})

	hidden := read_listing(fixture_dir, .Hidden_Only)
	defer free_listing(&hidden)
	expect_names(t, hidden.entries[:], []string{".hidden_dir", ".hidden_file"})

	visible := read_listing(fixture_dir, .Visible_Only)
	defer free_listing(&visible)
	expect_names(t, visible.entries[:], []string{"Banana", "apple", "cherry", "dir_one", "dir_two"})

	dirs := read_listing(fixture_dir, .Folders_Only)
	defer free_listing(&dirs)
	expect_names(t, dirs.entries[:], []string{".hidden_dir", "dir_one", "dir_two"})

	files := read_listing(fixture_dir, .Files_Only)
	defer free_listing(&files)
	expect_names(t, files.entries[:], []string{".hidden_file", "Banana", "apple", "cherry"})
}
