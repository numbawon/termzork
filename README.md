# termzork

Zork I, II, and III, playable in a browser, from one Docker container.

I used to have a Unix account on an old box of mine named `zork` whose
login shell wasn't `bash`, it was Zork itself: log in as that user and
you were dropped straight into the game, no shell ever exposed. This is
that trick again, over the web instead of SSH.

## Quick start

```bash
docker compose up -d
```

or without compose:

```bash
docker build -t termzork .
docker run -d -p 8080:8080 -p 7681:7681 termzork
```

Open `http://localhost:8080`, pick a game.

## How it works

One image, two processes, started by `entrypoint.sh`:

- **`busybox httpd`** on port 8080 serves the landing page
  (`landing/index.html`) — the ASCII art and the three Roman-numeral
  links.
- **`ttyd`** on port 7681 wraps `frotz` (the Z-machine interpreter) the
  way a shell login used to wrap Zork directly. One `ttyd` process
  serves all three games: `ttyd`'s `-a/--url-arg` flag lets a URL like
  `http://host:7681/?arg=zork1` pass `zork1` straight through as an
  argument to the wrapped command (`select.sh`), which execs `frotz` on
  the matching story file. No separate container or real Unix
  user-switching per game — the latter would need `login` to run as
  root with `setuid`, which this deliberately avoids. Neither process
  here needs root, so the whole thing runs as one fixed non-root user.

Story files come from Microsoft and Activision's November 2025
MIT-licensed release of the original ZIL source
(`github.com/historicalsource/zork1`, `zork2`, `zork3`). The Dockerfile
downloads each repo's pre-built `COMPILED/zorkN.z3` from a pinned commit
and checksums it — no ZIL compiler needed at build time, and no
ambiguity about whether it's legal to self-host: it's the real thing,
openly licensed.

## Configuration

| Env var | Default | What it does |
|---|---|---|
| `HTTP_PORT` | `8080` | Port the landing page listens on inside the container |
| `TTYD_PORT` | `7681` | Port the game terminal listens on inside the container |
| `ZORK_THEME` | green-on-black | An [xterm.js `ITheme`](https://xtermjs.org/docs/api/terminal/interfaces/itheme/) JSON object, applied to the terminal |

The landing page's links point at `TTYD_PORT` on whatever hostname you
loaded the page from (computed client-side, not hardcoded), so this
works unmodified on `localhost`, a LAN IP, or a real domain — as long as
both ports are reachable from wherever the browser is.

**Behind a single-hostname reverse proxy** (one hostname, no second
port exposed): route `/` to `HTTP_PORT` and give the game its own path
via `ttyd`'s `-b/--base-path`, same as you'd split any two backends
behind one host. That needs the landing page's port-swap script in
`landing/index.html` swapped for a path instead — not wired up here to
keep the default path simple, but it's a small change if you want it.

## Color

No `fontFamily` override anywhere in here on purpose: a client without
a pinned custom font installed degrades xterm.js's cell-metrics
measurement to a zero-size grid — a blank screen that still silently
accepts keystrokes, which is a much worse failure mode than an
unstyled-but-working terminal. Color (`ZORK_THEME`) doesn't have that
problem and is safe to override.

## Fixed: Chrome on Android blank-screen bug

There's an unfixed upstream bug ([tsl0922/ttyd#191](https://github.com/tsl0922/ttyd/issues/191),
closed "not planned") where a tall mobile viewport makes ttyd/xterm.js
report far more terminal rows than the screen can actually show at a
normal font size. Root-caused with a headless browser and real
WebSocket frame capture rather than guessed: frotz positions its
opening screen with an absolute cursor move computed from that row
count (`ESC[109d` on a wrongly-inflated 117-row terminal, confirmed
against the actual frames), so the exact same convention that looks
completely normal on an ordinary ~24-row terminal leaves most of the
screen blank on one that large.

The Dockerfile generates a custom ttyd index page (`-I`) that caps the
terminal container's height under a `max-width` media query, so only
phone-shaped viewports are affected and desktop keeps the full window.
Deliberately does **not** use `-t fontSize`/`-t rendererType` to try to
fix this — an earlier attempt at exactly that made it worse, because
either one forces xterm.js to re-measure cell metrics right after
connecting, which triggers a *second* resize once frotz has already
drawn its opening screen. frotz's redraw-on-resize is what actually
causes the blank screen; the row-count miscalculation just made it
visible. Theme colors and `cursorBlink` don't touch cell metrics, so
they don't trigger a re-fit and stay in `entrypoint.sh`.

## Credits

- [Zork I](https://github.com/historicalsource/zork1),
  [II](https://github.com/historicalsource/zork2),
  [III](https://github.com/historicalsource/zork3) — Infocom, 1980–1982;
  MIT-licensed by Microsoft and Activision, November 2025
- [frotz](https://gitlab.com/DavidGriffith/frotz) — the Z-machine
  interpreter that actually runs the games
- [ttyd](https://github.com/tsl0922/ttyd) — shares a terminal over the
  web

## License

MIT for everything in this repository — see [LICENSE](LICENSE). The
Zork story files carry their own MIT license from the November 2025
release; this repo doesn't relicense them, just downloads and checksums
them at build time.
