# niffler-weather

A [Niffler](https://github.com/gokr/niffler) component package: current
weather and multi-day forecast for any place on Earth, via
[Open-Meteo](https://open-meteo.com). No API key, no configuration.

## Install

From a running Niffler harness, just say:

> Install the package `gokr/niffler-weather`

The agent's `plugins` component searches GitHub (`topic:niffler-component`),
clones this repo, downloads a prebuilt binary for your platform from the
latest release (or compiles from source via the `builder` component), and
spawns it — the tools appear in the conversation immediately and come back
on every boot. Each spawn is human-approved.

Two new tools:

- `weather_current {place}` — temperature, feels-like, humidity, wind,
  condition summary
- `weather_forecast {place, days}` — daily min/max, rain chance, conditions

## Uninstall / update

> Remove the niffler-weather package
> Update the niffler-weather package

## Publishing your own package

This repo is the layout convention:

```
niffler.json        # package manifest (required)
<comp>/main.nim     # one directory per component (Nim)
<comp>/main.go      # ... or Go
.github/workflows/  # optional: build release assets so installs need
                    # no toolchain on the user's machine
```

`niffler.json`:

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "components": [
    {"name": "mything", "lang": "nim", "main": "mything/main.nim"}
  ]
}
```

- `name` is the package name users pass to `plugin_remove`/`plugin_update`.
- Each component gets one binary; `name`, `lang` (`nim` or `go`), `main`
  (entry source file) are required, `env` (required env var names) optional.
- To make the package discoverable, add the GitHub topic
  [`niffler-component`](https://github.com/topics/niffler-component) to
  your repo.
- Tag releases (`v1.0.0`) so installs pin to them; the included workflow
  cross-builds release assets named `<component>-<os>-<arch>` so hosts
  without Nim/Go get prebuilt binaries. Currently prebuilt assets ship for
  Linux x86-64 (`weather-linux-amd64`); other platforms install from
  source via the harness's `builder` (a Niffler install already has
  nats.c, libclang and the SDK deps).

Components are plain Niffler components — the SDK pattern is in
[Niffler's README](https://github.com/gokr/niffler#writing-a-component).
They run with the harness the moment they're spawned: doc comments become
the LLM's tool descriptions.

## License

MIT — see [LICENSE](LICENSE).
