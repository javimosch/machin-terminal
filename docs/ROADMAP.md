# machin-terminal — Roadmap

Ordered by value toward the [north star](VISION.md): be the best possible *host* for
a shell, full-screen TUIs, and **tmux**. Multiplexing is tmux's job (see VISION).

## Done

- **1 — PTY core** (`spike/pty-relay.src`): `forkpty` a real shell and relay I/O.
  Proves PTY + fork/exec + raw fd I/O + poll in pure MFL.
- **2 — windowed terminal**: raylib glyph grid ← VT parser ← non-blocking PTY drain;
  keystrokes encoded back. Printable text, `\r \n \b \t`, wrap, scroll, SGR
  16/256/truecolor, cursor moves, erase.
- **3 — VT100/xterm subset**: alt-screen (`?47/?1047/?1049`), scroll region
  (DECSTBM) + IND/RI/NEL + SU/SD, IL/DL, ICH/DCH/ECH, save/restore cursor
  (DECSC/DECRC, CSI s/u), reverse video (SGR 7/27), cursor visibility (`?25`),
  app-cursor-keys (`?1`), resizable window → `ioctl(TIOCSWINSZ)`/SIGWINCH,
  `TERM=xterm-256color`. **Verified: `vim`, `htop`, alt-screen enter/restore.**
  **tmux verified running** (panes/splits/status bar render).
- **4 — UTF-8 output decoding.** Multi-byte UTF-8 from the PTY is accumulated into a
  single codepoint before `putc`. **Verified: tmux box-drawing borders render.**
- **5 — Font glyph coverage.** `LoadFontEx` bakes ASCII + Latin-1 + general
  punctuation + arrows + box-drawing/blocks/shapes + Braille into the atlas.
- **6 — Mouse reporting.** X10 and SGR (1006) encoding to the PTY: button
  press/release, wheel, drag (button-event 1002 / any-event 1003), and
  shift/alt/ctrl modifiers. *(Click injection not auto-tested here — no xdotool;
  verified against the xterm spec.)*
- **7 — Scroll = `O(rows)`.** A row-pointer map (`rmap`: logical→physical row) makes
  scrolling rotate pointers + clear one row instead of copying every cell. Realistic
  cat-like throughput 41 → **144 MB/s** (see [BENCHMARK.md](BENCHMARK.md)).
- **8 — Mouse selection + clipboard.** Drag-to-select on the grid (or Shift-drag when
  an app holds the mouse), copy to the system clipboard, paste via middle-click /
  Ctrl+Shift+V with **bracketed paste** (`?2004`). Selection-text extraction verified
  headlessly; the drag + clipboard FFI need interactive testing.
- **9 — Theming delegated to the shell.** Theming lives in zsh + omz/p10k, not here
  (see [VISION.md](VISION.md)). The terminal owns only the two pieces the shell can't:
  **OSC 4 / 10 / 11** (palette + default fg/bg, so `base16-shell`-style scripts repaint
  it) and a **configurable Nerd-Font** (`MTERM_FONT` / `MTERM_FONT_SIZE` + baked
  powerline/PUA glyphs) so p10k icons render. OSC parsing verified headlessly.

## Next — daily-driver quality

- **10 — Text attributes.** Bold (distinct from bright), underline, italic, dim,
  inverse already done; strike. Needs bold/italic font faces or synthesis.
- **11 — Native scrollback.** Backlog above the viewport with wheel/PageUp.
  *Lower priority:* in a tmux-centric workflow tmux owns scrollback; this mainly
  helps the moments you're outside tmux.

## Polish / correctness backlog

- Cursor shapes (DECSCUSR) + blink; focus in/out events (`?1004`).
- True Unicode width: wide (CJK/emoji) and zero-width/combining glyphs.
- DEC special-graphics charset (`ESC(0`) mapping (fallback when a TUI isn't UTF-8).
- OSC 52 clipboard (let remote apps set the clipboard).
- Render perf: dirty-region redraw / render-to-texture if needed at large sizes.

## Explicit non-goals

Native tiling / tabs / splits / sessions (**use tmux**); prompt themes / color schemes
(**use zsh + omz/p10k**; the terminal owns only the OSC palette + font); a plugin/
scripting runtime; being a multiplexer or window manager. See [VISION.md](VISION.md).
