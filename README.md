# machin-terminal

A minimal, fast, correct **single-window terminal emulator** written in
**pure [MFL](https://github.com/javimosch/machin)** (the machin language). One ~1.1 MB
static binary — no GTK, no VTE, no Python — just MFL through the C FFI for the PTY and
raylib for pixels. **[tmux](https://github.com/tmux/tmux) is the multiplexer**, so
there are no native tabs/splits ([why](docs/VISION.md)).

🌐 **[Landing & changelog](https://javimosch.github.io/machin-terminal/)** ·
📥 **[Releases](https://github.com/javimosch/machin-terminal/releases)** ·
🧭 **[Vision](docs/VISION.md)** · **[Roadmap](docs/ROADMAP.md)** · **[Benchmarks](docs/BENCHMARK.md)** · **[Agent guide](AGENTS.md)**

## Status

- **Step 1 — PTY core** (`spike/pty-relay.src`): `forkpty` a real bash and relay its
  I/O with zero byte-marshaling. Proves the hard layer (PTY + fork/exec + raw fd
  I/O + poll) works in MFL.
- **Step 2 — windowed terminal**: a raylib window rendering a glyph grid driven by
  a VT escape-sequence parser, with keystrokes encoded back to the PTY. Printable
  text, `\r \n \b \t`, line wrap, scroll, SGR colors (16 / 256 / truecolor), cursor
  moves, erase.
- **Step 3 — VT100/xterm subset** (`term.src`): the machinery full-screen TUIs need.
  Alt-screen buffer (`?47/?1047/?1049`), scroll region (DECSTBM) + IND/RI/NEL +
  SU/SD, insert/delete lines (IL/DL) and chars (ICH/DCH/ECH), save/restore cursor
  (DECSC/DECRC, CSI s/u), reverse video (SGR 7/27), cursor visibility (`?25`),
  application cursor keys (`?1`), and a **resizable window** that recomputes
  rows/cols and SIGWINCHes the shell via `ioctl(TIOCSWINSZ)`.
- **Step 4 — UTF-8 + fonts**: multi-byte UTF-8 output decoding and a wider font atlas
  (Latin-1, box-drawing, blocks, arrows, Braille) — **tmux pane borders render as
  solid lines**.
- **Step 5 — mouse reporting**: X10 + SGR (`?1006`) encoding to the PTY — button
  press/release, wheel, drag (`?1002`/`?1003`), and shift/alt/ctrl modifiers.

**Verified running `vim`, `htop`, and `tmux`**, with correct alt-screen enter/restore.
Optional dev hook: set `MTERM_SEED="cmd\r"` to type a command into the shell at startup
(used for headless screenshot testing).

## Roadmap

Next up (see [docs/ROADMAP.md](docs/ROADMAP.md)): mouse selection + clipboard, bold/
underline/italic attributes, native scrollback, configurable font/colors. Native
tiling/tabs are a **non-goal** — that's tmux's job.

## Build & run

```sh
./build.sh                 # vendors static raylib 5.0 if needed, builds ./machin-terminal
DISPLAY=:0 ./machin-terminal
```

Requires a monospace font at `/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf`.

## Links

- **[machin](https://github.com/javimosch/machin)** — the MFL language & compiler this is built with
- **[awesome-machin](https://github.com/javimosch/awesome-machin)** — the curated list of things built with machin
- Built by **[@javimosch](https://github.com/javimosch)** as a machin dogfood project.
