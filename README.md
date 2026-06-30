# machin-terminal

A minimal, fast, correct **single-window terminal emulator** written in
**pure [MFL](https://github.com/javimosch/machin)** (the machin language). One ~1.1 MB
static binary — no GTK, no VTE, no Python — just MFL through the C FFI for the PTY and
raylib for pixels. **[tmux](https://github.com/tmux/tmux) is the multiplexer**, so
there are no native tabs/splits ([why](docs/VISION.md)).

🌐 **[Landing & changelog](https://javimosch.github.io/machin-terminal/)** ·
📥 **[Releases](https://github.com/javimosch/machin-terminal/releases)** ·
🧭 **[Vision](docs/VISION.md)** · **[Roadmap](docs/ROADMAP.md)** · **[Benchmarks](docs/BENCHMARK.md)** · **[Agent guide](AGENTS.md)**

## Install

Linux x86_64 (needs an X11 display + OpenGL — works on Ubuntu/GNOME, and on Wayland via XWayland):

```sh
curl -fsSL https://raw.githubusercontent.com/javimosch/machin-terminal/master/install.sh | bash
machin-terminal --version
```

The script downloads the latest release binary to `~/.local/bin` (or `/usr/local/bin`),
checks runtime deps, and adds a desktop entry. Or grab the binary yourself from
[Releases](https://github.com/javimosch/machin-terminal/releases). Verify any build
headlessly with `machin-terminal --version` / `--help` (no window).

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
- **Step 6 — perf**: `O(rows)` scroll via a row-pointer map — realistic cat-like
  throughput **41 → 144 MB/s** (see [docs/BENCHMARK.md](docs/BENCHMARK.md)).
- **Step 7 — selection + clipboard**: drag-to-select (or Shift-drag), copy on release /
  Ctrl+Shift+C, paste via middle-click / Ctrl+Shift+V with bracketed paste.
- **Step 8 — OSC palette + fonts**: OSC 4/10/11 (shell sets the palette), configurable
  Nerd-Font (`MTERM_FONT`) + powerline glyphs.

**Verified running `vim`, `htop`, and `tmux`**, with correct alt-screen enter/restore.
Optional dev hook: set `MTERM_SEED="cmd\r"` to type a command into the shell at startup
(used for headless screenshot testing).

## Theming

Theming is delegated to the shell — use **zsh + [Oh My Zsh](https://ohmyz.sh/) /
[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** for your prompt, git
status, and colors. machin-terminal owns only what the shell can't: the palette
(set it from your `~/.zshrc` via OSC 4/10/11, e.g. `base16-shell`) and the font.
Point `MTERM_FONT` at a Nerd Font for p10k icons. Native prompt themes are a
**non-goal** ([why](docs/VISION.md)).

## Build & run

```sh
./build.sh                       # vendors static raylib 5.0 if needed, builds ./machin-terminal
DISPLAY=:0 ./machin-terminal

MTERM_FONT=~/.fonts/MesloLGS-NF.ttf MTERM_FONT_SIZE=22 ./machin-terminal   # custom font
```

Defaults to `/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf` if `MTERM_FONT` is unset.

## Links

- **[machin](https://github.com/javimosch/machin)** — the MFL language & compiler this is built with
- **[awesome-machin](https://github.com/javimosch/awesome-machin)** — the curated list of things built with machin
- Built by **[@javimosch](https://github.com/javimosch)** as a machin dogfood project.
