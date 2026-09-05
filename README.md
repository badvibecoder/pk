# pk — peek

A fast, colorful `ls` replacement written in [Odin](https://odin-lang.org/).

`pk` lists a directory like `ls`, but shows hidden files by default, prints
human-readable sizes, and color-codes entries. It is built performance-first:
it reads entries with raw `getdents` (zero per-entry `stat` for a plain
listing), sorts with an inlined quicksort, and emits the whole listing in one
buffered write.

## Features

| Command | What it does |
|---|---|
| `pk` | list everything (hidden + visible), columnar, colored |
| `pk -h` | hidden entries only |
| `pk -nh` | visible (non-hidden) entries only |
| `pk -f` | folders only, including hidden |
| `pk -fi` | files only, including hidden |
| `pk -t` | tree of everything — directories first, hidden included |
| `pk -nht` | tree of visible entries only |
| `pk -d` | details: permissions, links, owner, group, size, time |
| `pk … -s` | write output to `pk-snap-<datetime>` instead of stdout |
| `pk --help` | show the built-in help index |

Flags combine: `-s` can be added to any command (e.g. `pk -nht -s`).

Any command also accepts a directory path — `pk ~/something`, `pk -d /var/log`,
`pk -nht -s ~/projects`. It defaults to the current directory.

### Styling (when printing to a terminal)

| Kind | Style |
|---|---|
| folder | bold |
| hidden file | red |
| hidden folder | bold + red |
| file | plain |

Piping or redirecting output strips the colors automatically (like `ls`).

### `-d` details

Like `ls -al` — permissions, link count, owner, group, date, and name — with
human sizes (`KB` under 1 MB, `MB` under 1 GB, `GB` above), local timestamps,
owner/group names resolved from `/etc/passwd` and `/etc/group`, and symlink
targets (`name -> target`). It omits `.`/`..` and the `total` line.

## Examples

```
$ pk
.cfg  .secret  readme  subdir            (colored when interactive)

$ pk -d
-rw-r--r-- 1 pcarroll pcarroll 234KB Sep  4 18:23 big_kb
lrwxrwxrwx 1 pcarroll pcarroll   0KB Sep  4 18:23 link_to_plain -> plain

$ pk -nht
.
├── docs
│   └── guide.md
└── src
    └── main.odin

$ pk /var/log
alternatives.log  apt  btmp  dpkg.log  journal  lastlog  wtmp
```

## Install

Requires the [Odin](https://odin-lang.org/docs/install/) compiler. Linux only —
`pk` calls Linux syscalls (`getdents`, `fstatat`, `ioctl`) directly.

```sh
# build the release binary
odin build src -out:pk -o:speed

# run the test suite (23 tests)
odin test src

# run
./pk
./pk -d
./pk -nht -s

# install to your PATH
sudo cp pk /usr/local/bin/pk
```

## Benchmarks

Measured on Linux (tmpfs, warm cache, `-o:speed`), averaged over multiple
runs. Numbers vary by machine and filesystem.

| Scenario | `pk` | `ls` |
|---|---|---|
| flat list, 60,000 entries | ~25 ms | ~53 ms (`ls -1`) |
| details, 60,000 entries | ~110 ms | ~356 ms (`ls -al`) |
| tree, 4,200 entries / 200 dirs | ~6 ms | ~8 ms (`ls -R`) |

`pk -d` stage breakdown (60,000 entries): read 16 ms · sort 4 ms · stat 62 ms
(one `fstatat` per entry) · format 20 ms · write ~1 ms.

On a real directory (`/usr/bin`, 1,343 entries), averaged over 15 runs:

| Scenario | `pk` | `ls` |
|---|---|---|
| flat | 3 ms | 6 ms (`ls -1`) |
| details | 6 ms | 12 ms (`ls -al`) |

## Project layout

A single Odin package in `src/`; tests live alongside as `*_test.odin`.

| File | Role |
|---|---|
| `main.odin` | parse → read → sort → (stat) → format/tree → write pipeline |
| `args.odin` | flag parsing + the `--help` text |
| `options.odin` | `Command` enum + `Options` |
| `read.odin` | raw `getdents` enumeration + filter |
| `sort.odin` | inlined quicksort + comparators |
| `color.odin` | TTY detection (`ioctl`) + ANSI styles |
| `layout.odin` | flat columnar output |
| `detail.odin` | `-d`: stat, mode string, mtime, column layout |
| `size.odin` | KB/MB/GB formatting |
| `tree.odin` | recursive tree walker (`openat`, dirs-first) |
| `user.odin` | `/etc/passwd` + `/etc/group` name lookup |
| `snapshot.odin` | `-s` filename (`pk-snap-<datetime>`) |
| `timezone.odin` | `localtime_r` FFI for local timestamps |
| `timing.odin` | per-stage monotonic timers |

## How it works

- **Fast reads** — `os.read_dir` stats every entry; `pk` reads raw `getdents`
  and takes `d_type` from the dirent, so a plain listing does zero `stat`
  calls. `-d` stats once per entry with `fstatat`.
- **Fast sort** — a small inlined quicksort (median-of-three + insertion
  sort) instead of the stdlib's closure-based smoothsort.
- **One write** — output is built into a single buffer and written once.
- **Measure it** — `PK_TIME=1 pk …` prints per-stage timings to stderr.

## Known differences from `ls`

- Human sizes (`234KB`) instead of raw bytes.
- No `.`/`..` and no `total` line in `-d`.
- Flat listing sorts byte-order (case-sensitive), not locale-aware.
- Uniform space padding in columns (no tabs).
- Linux-only, and snapshot filenames resolve to the second.
