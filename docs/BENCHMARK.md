# Benchmarks

Honest, reproducible numbers for machin-terminal v0.1.0, measured on the dev machine
(Linux x86_64). The goal is to show where a pure-MFL terminal is genuinely fast — and
to be candid where it isn't.

> TL;DR — machin-terminal wins decisively on **binary size, zero runtime deps, and raw
> VT-parser speed** (a native engine compiled through C). It does **not** win on RAM:
> any GPU-rendered terminal pays for the OpenGL driver, so idle RSS is comparable to
> GTK terminals.

## 1. Binary size & dependencies (on disk)

A terminal's "weight" is mostly its rendering/toolkit stack. machin-terminal is one
static binary that bundles its whole engine (raylib), linking only libc/libm; OpenGL
and X11 are `dlopen`ed at runtime.

| Terminal | Executable | Toolkit / engine it pulls in |
|---|---:|---|
| **machin-terminal** | **1.1 MB** (one binary) | none — static raylib; only `libc`, `libm` dynamically linked |
| gnome-terminal | 3.4 KB launcher | + `gnome-terminal-server` 363 KB + `libvte` 527 KB + **`libgtk-3` 8.2 MB** + `libgdk-3` 1.1 MB + glib/pango/cairo/harfbuzz/… |

`ldd machin-terminal` → 4 lines (`linux-vdso`, `libm`, `libc`, `ld-linux`). That's the
entire dependency surface.

## 2. VT-parser throughput (headless engine speed)

The core question for "is the emulator fast": how quickly does it consume the byte
stream from the PTY? Measured by feeding a representative colored-shell-output stream
through the **real `feed()` parser** (same code the live terminal runs), no window.

| Workload | Throughput | Per byte |
|---|---:|---:|
| **Parser core** (SGR + cursor, in-place, no scroll) | **172 MB/s** | **5 ns** |
| Realistic `cat`-like (colored lines + CRLF, scrolls) | 41 MB/s | 24 ns |

The parser itself runs at ~5 ns/byte. The realistic figure is lower because it is
dominated by the screen **scroll** — currently an `O(rows × cols)` cell copy per
newline. A row-pointer ring buffer would make scroll `O(1)` and close most of that gap
(a tracked optimization). For reference, 41 MB/s is ~one 50 MB `cat` per 1.2 s of
dense, newline-heavy output.

Reproduce:

```sh
MTERM_BENCH=2 ./machin-terminal   # parser core (no scroll)
MTERM_BENCH=1 ./machin-terminal   # realistic cat-like (with scroll)
```

## 3. Idle memory (RSS) — the honest caveat

| Terminal | Idle RSS |
|---|---:|
| gnome-terminal-server | ~61 MB |
| machin-terminal | ~73 MB |

machin-terminal is **not** lighter on RAM. Both numbers are dominated by shared GPU
and toolkit pages: raylib initializes a full OpenGL context (Mesa/driver mappings),
GTK terminals map their toolkit. RSS is the wrong axis to claim a win on for a
GPU-rendered terminal — so we don't. (A software-rendered backend would change this,
but that's not the current design.)

## What "fast" means here

- ✅ **Tiny, self-contained binary** — 1.1 MB, no GTK/VTE/Python/Node, only libc/libm.
- ✅ **No language runtime** — MFL compiles through C to native; instant cold start,
  no interpreter/JIT warmup.
- ✅ **Fast native VT parser** — ~5 ns/byte core; competitive engine for a hand-written
  emulator in a young language.
- ➖ **RAM is comparable**, not lower — the OpenGL driver dominates (see §3).
- 🔜 **Scroll is the next perf win** — `O(1)` row-pointer ring buffer.

Methodology is intentionally simple and reproducible; numbers will move as the
implementation and hardware change. Re-run the parser benchmark with the `MTERM_BENCH`
env var above.
