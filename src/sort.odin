package main

sort_entries :: proc(entries: []Entry) {
	quicksort(entries)
}

quicksort :: proc(a: []Entry) {
	a := a
	for len(a) > 16 {
		p := partition(a)
		quicksort(a[:p])
		a = a[p+1:]
	}
	insertion_sort(a)
}

partition :: proc(a: []Entry) -> int {
	lo, mid, hi := 0, len(a)/2, len(a)-1
	if entry_less(a[mid], a[lo]) { a[mid], a[lo] = a[lo], a[mid] }
	if entry_less(a[hi], a[lo])  { a[hi], a[lo]  = a[lo], a[hi] }
	if entry_less(a[hi], a[mid]) { a[hi], a[mid] = a[mid], a[hi] }
	pivot := a[mid]
	a[mid], a[hi] = a[hi], a[mid]
	i := 0
	for j in 0..<hi {
		if entry_less(a[j], pivot) {
			a[i], a[j] = a[j], a[i]
			i += 1
		}
	}
	a[i], a[hi] = a[hi], a[i]
	return i
}

insertion_sort :: proc(a: []Entry) {
	for i in 1..<len(a) {
		for j := i; j > 0 && entry_less(a[j], a[j-1]); j -= 1 {
			a[j], a[j-1] = a[j-1], a[j]
		}
	}
}

name_less :: #force_inline proc(a, b: string) -> bool {
	n := min(len(a), len(b))
	for i in 0..<n {
		if a[i] != b[i] {
			return a[i] < b[i]
		}
	}
	return len(a) < len(b)
}

entry_less :: #force_inline proc(a, b: Entry) -> bool {
	return name_less(a.name, b.name)
}

entry_less_tree :: proc(a, b: Entry) -> bool {
	if a.is_dir != b.is_dir {
		return a.is_dir
	}
	return name_less(a.name, b.name)
}
