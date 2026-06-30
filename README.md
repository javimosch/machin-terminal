# machin-terminal

A lightweight Linux terminal emulator written in **pure [MFL](https://github.com/javimosch/machin)** —
a leaner, single-static-binary alternative to Terminator/GTK+VTE. No GTK, no VTE,
no Python: just MFL through the C FFI for the PTY, and raylib for pixels.

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
  rows/cols and SIGWINCHes the shell via `ioctl(TIOCSWINSZ)`. **Verified running
  `vim` and `htop`**, with correct alt-screen enter/restore.

  Optional dev hook: set `MTERM_SEED="cmd\r"` to type a command into the shell at
  startup (used for headless screenshot testing).

## Roadmap

4. Scrollback history (the main-screen backlog above the viewport).
5. Tiling / tabs / split panes — the Terminator-parity layer.
6. Polish: bold/underline/italic attributes, mouse reporting, selection + clipboard,
   configurable font/colors, true Unicode width (wide/combining glyphs).

## Build & run

```sh
./build.sh                 # vendors static raylib 5.0 if needed, builds ./machin-terminal
DISPLAY=:0 ./machin-terminal
```

Requires a monospace font at `/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf`.
