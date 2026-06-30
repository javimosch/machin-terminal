# machin-terminal — Vision

## North star

**A minimal, fast, correct single-window terminal emulator written in pure
[MFL](https://github.com/javimosch/machin) — one static native binary, no GTK,
no VTE, no Node, no interpreter.**

machin-terminal is to terminals what `st`/`foot`/early-`alacritty` are: *one fast,
correct pane of glass*. It draws a character grid, speaks the xterm escape-sequence
protocol faithfully, talks to a PTY, and gets out of the way. It is **not** a
window manager, a multiplexer, or a session manager.

> Do one thing well: be the best possible *host* for a shell and for full-screen
> terminal programs. Delegate everything above the glass.

## Why this, and why machin

machin-terminal is a **dogfood** of the machin language (the project's broader north
star: *the POC is done — now build real tools and let real usage drive the
language's features*). A terminal emulator is an unusually good forcing function:

- The **VT escape-sequence parser** is a meaty state machine — the same kind of
  systems code as the machin self-host lexer/parser.
- The **PTY + raw fd + ioctl** layer exercises the C FFI hard (`forkpty`, `poll`/
  non-blocking I/O, `ioctl(TIOCSWINSZ)`, `setenv`).
- The **renderer** drives the raylib FFI (glyph grid, input, resize).
- It is genuinely *useful* and genuinely *lightweight* — a ~1 MB static binary vs.
  Python + GTK + VTE.

Every gap it hits (UTF-8 decoding, font atlas coverage, mouse reporting) is a
concrete, real-world feature request for the language and its libraries.

## The tmux thesis (why there is no native tiling)

Terminator bundles splits/tabs/sessions *into the emulator* because GTK/VTE gives it
no other layer. We have a better layer: **tmux**. tmux already does splits, tabs,
sessions, detach/reattach, layouts, and scripting — better than we would reasonably
reimplement — and it runs *inside any correct terminal*.

machin-terminal already hosts full-screen ncurses apps (`vim`, `htop`) and runs tmux
(panes, splits, and status bar render; remaining glitches are glyph-fidelity bugs,
not multiplexing bugs). So **native tiling would be a worse, non-persistent copy of
something the user already runs.** We don't build it.

This sharpens the mission: instead of "a lightweight Terminator" (emulator **+**
multiplexer), machin-terminal is **"a minimal correct terminal; tmux is the
multiplexer."** The headline acceptance test becomes: *does tmux run flawlessly
inside it?*

## The theming thesis (delegate the prompt to zsh / Oh My Zsh)

The same logic applies one layer up. The **prompt, git status, syntax highlighting,
and per-character colors** are the shell's job — Oh My Zsh / Powerlevel10k emit them
as SGR sequences + glyphs, and the terminal already renders those. So machin-terminal
builds **no** prompt themes, color schemes, or prompt config. The intended stack is:

> **machin-terminal** (the glass) → **tmux** (multiplexing) → **zsh + omz/p10k**
> (prompt, theme, highlighting).

Only two pieces of "theming" can't be delegated, because the shell physically can't do
them — and the terminal owns exactly those, minimally:

1. **The ANSI palette + default fg/bg.** The terminal defines what "green" (SGR 32)
   looks like. But we hand even this back to the shell: **OSC 4 / 10 / 11** let a
   startup script (`base16-shell`, an omz theme) repaint the palette. So palette
   theming is *also* a shell-startup concern, not a built-in config format.
2. **The font.** p10k's icons are Nerd-Font glyphs the shell can't supply — the
   terminal must load a font that has them. Hence a configurable font path
   (`MTERM_FONT`) + baked powerline/PUA glyph ranges. This is the one irreducible
   terminal-side "theme" responsibility.

Everything else about how your terminal *looks* lives in your `~/.zshrc`, not here.

## What "done enough to daily-drive" means

- Runs a login shell, `vim`, `htop`, `less`, `git`, and **tmux** with no visible
  rendering artifacts.
- Correct colors (16 / 256 / truecolor), text attributes, Unicode glyphs (incl.
  box-drawing and common symbols), and cursor behavior.
- Mouse works (reporting passthrough) and you can select + copy text.
- Resizes cleanly (SIGWINCH) and starts fast.

## Non-goals (by design)

- **Native tiling / tabs / splits / sessions** — use tmux.
- **Prompt themes / color schemes / prompt config** — use zsh + Oh My Zsh / p10k
  (the terminal only owns the palette via OSC and the font).
- A config language, plugin system, or scripting runtime — keep it small.
- Being a multiplexer or a window manager.

## Maybe-someday (only if real usage demands it)

GPU-accelerated rendering, font ligatures, the kitty/sixel image protocols,
ANSI-art-grade compatibility. None are on the critical path; the bar is "what does
daily use actually require."
