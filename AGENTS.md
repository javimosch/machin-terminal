# AGENTS.md — working on machin-terminal

Guide for AI agents (and humans) hacking on this repo. Read
[docs/VISION.md](docs/VISION.md) and [docs/ROADMAP.md](docs/ROADMAP.md) first for
*what* and *why*; this file is *how*.

## What this is

A terminal emulator in **pure MFL** (the machin language), rendering with raylib and
talking to a PTY via the C FFI. One static binary. Multiplexing is delegated to tmux
— **do not add native tiling/tabs** (see VISION).

## Layout

```
term.src              # the emulator — the whole program, one file
build.sh              # encode .src -> .mfl, link static raylib, build ./machin-terminal
spike/pty-relay.src   # step-1 PTY proof (forkpty + relay); kept as reference
docs/VISION.md docs/ROADMAP.md
```

Source is authored as **`.src`** (loose, Go-like). `machin encode` mints the
canonical one-declaration-per-line **`.mfl`**; `machin build` compiles the `.mfl`.
Edit the `.src`, never the generated `.mfl` (gitignored).

## Build & run

```sh
./build.sh                          # -> ./machin-terminal (vendors static raylib 5.0 to /tmp/rl)
DISPLAY=:0 ./machin-terminal        # opens the window, spawns bash on a PTY
```

`MACHIN=/path/to/machin ./build.sh` to use a specific compiler.

## Verify a change (headless screenshot loop)

There is no `xdotool`/`wmctrl` here, so we drive the shell with the **`MTERM_SEED`**
env hook (types a command into the PTY at startup) and screenshot the X root with
ImageMagick `import`:

```sh
MTERM_SEED=$'htop\r' DISPLAY=:0 ./machin-terminal >/dev/null 2>&1 &   # or vim, tmux, ls...
sleep 3
DISPLAY=:0 import -window root /tmp/shot.png                          # then read the PNG
kill %1
```

Good stress tests, in increasing order: `ls --color=always /usr` (SGR + wrap) →
`vim <file>` / `htop` (alt-screen, reverse video, scroll region) →
`unset TMUX; tmux new-session \; split-window -h` (UTF-8 box-drawing, the hardest).
Always confirm a real change with a screenshot, not just a clean build.

## Architecture (term.src)

- **One extern boundary.** All C FFI lives in the `extern` blocks at the top
  (raylib, pty, unistd, fcntl, wait, ioctl, stdlib). Everything else is pure MFL.
- **`Term` global `T`.** All emulator state (grid, cursor, parser state, scroll
  region, the two screen buffers) hangs off one top-level `var T`. The active grid
  (`T.ch/T.cfg/T.cbg`) is a **slice alias** swapped between the main (`T.m*`) and alt
  (`T.a*`) buffers on alt-screen mode changes.
- **Pipeline each frame:** `checkResize` → `drainPty` (non-blocking read, byte →
  `feed`) → `handleInput` (raylib keys → PTY bytes) → `drawGrid` (cells → glyphs).
- **`feed(b)` is the VT state machine** (states: ground / ESC / CSI / OSC / charset).
  Add new escape handling there and in `csiDispatch` / `privMode`.
- Colors are stored as **int RGB** per cell (never raylib `Color` — see gotchas).

## MFL gotchas (learned the hard way — save yourself the rebuild)

- **Functions are type-inferred.** No param/return type annotations; use named
  returns: `func f(a, b) (out) { out = ... }`. Only `extern` fns are typed.
- **No C-style `for`.** Only `for cond { }` and `for x := range xs { }`. Use a
  manual index: `i := 0; for i < n { …; i = i + 1 }`.
- **`make` is chan/map only.** Slices grow with `append`; see the `zeros(n)` helper.
- **Top-level `var` needs an initializer** (`var PAL = []int{}`, not `var PAL []int`).
- **No `peek_u8`/`peek_u16`.** Read bytes from a raw buffer via an aligned
  `peek_i32` + shift/mask (see `drainPty`). Writing is fine: `poke_u8/u16/i32/ptr`.
- **C FFI types:** `string` arg auto-converts to `char*`; `ptr` is `void*`/`T*` as an
  int; pass literal `0` for `NULL`; `i32/u8/u16/u32/f32` as named.
- **cstructs can't be MFL `struct` fields.** `Color`/`Vector2`/`Font` may be locals,
  params, or slice elements — but not fields of `type T struct`. (Hence int-RGB cells
  and a `Font` local passed into `drawGrid`.)
- **f32/f64 cstruct fields won't take a concrete int** — convert with `float(x)`
  (e.g. `Vector2{float(c) * cwf, ...}`).
- **Static raylib needs explicit link deps** — `link "m"/"pthread"/"dl"/"rt"/
  "X11"/"GL"` — because machin only auto-links `-lm` when MFL uses math builtins.
- **`println` is buffered to exit; raw `write(1, …)` is immediate** — they don't
  interleave. (Irrelevant in the GUI, but bites in CLI debugging.)

When in doubt about the language surface, run `machin guide` (JSON; `--text` for
prose) — it's the version-exact feature catalog for the installed compiler.

## Conventions

- Keep `term.src` **system-style** (e.g. `header "raylib.h"`); `build.sh` injects the
  vendored include/lib paths. Don't hardcode `/tmp/rl` outside the build seam.
- Add the smallest escape-sequence handling that makes a real app render; verify with
  a screenshot of that app.
- Don't commit the build outputs (`machin-terminal`, `*.mfl`).
- Commit/push only when the human asks.
