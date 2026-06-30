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

## Now — make tmux (and Unicode TUIs) pixel-perfect

These are the gaps the tmux run exposed. They are the critical path.

- **4 — UTF-8 output decoding.** Accumulate multi-byte UTF-8 from the PTY into a
  single codepoint before `putc`. Today each byte is treated as its own codepoint,
  so box-drawing/accented/symbol glyphs shatter into garbage. *(Blocks tmux borders,
  any non-ASCII output.)*
- **5 — Font glyph coverage.** `LoadFontEx` currently loads only 95 ASCII glyphs;
  anything above renders as `?`. Load Latin-1 + box-drawing (U+2500–U+257F) + block
  elements + common symbols (and a sane fallback). *(With #4, fixes the tmux `???`.)*
- **6 — Mouse reporting passthrough.** Encode X10/SGR (1006) mouse events to the PTY
  so the mouse works in tmux, vim, less. Probably the biggest usability gap after
  glyphs.

## Next — daily-driver quality

- **7 — Mouse selection + clipboard.** Drag-to-select on the grid; copy to the X11
  clipboard; paste (with bracketed-paste). Emulator-level — tmux can't do this for
  you. (Also support OSC 52.)
- **8 — Text attributes.** Bold (distinct from bright), underline, italic, dim,
  inverse already done; strike. Needs bold/italic font faces or synthesis.
- **9 — Native scrollback.** Backlog above the viewport with wheel/PageUp.
  *Lower priority:* in a tmux-centric workflow tmux owns scrollback; this mainly
  helps the moments you're outside tmux.
- **10 — Configuration.** Font family/size, color palette, default geometry,
  cursor style — via a simple file or flags.

## Polish / correctness backlog

- Cursor shapes (DECSCUSR) + blink; focus in/out events (`?1004`).
- True Unicode width: wide (CJK/emoji) and zero-width/combining glyphs.
- DEC special-graphics charset (`ESC(0`) mapping (fallback when a TUI isn't UTF-8).
- Bracketed-paste *forwarding* to apps (`?2004`), not just swallowing.
- Performance pass (dirty-region redraw, render-to-texture) if needed at large sizes.

## Explicit non-goals

Native tiling / tabs / splits / sessions (**use tmux**); a plugin/scripting runtime;
being a multiplexer or window manager. See [VISION.md](VISION.md).
