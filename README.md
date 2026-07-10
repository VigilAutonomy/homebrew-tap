# Vigil Homebrew Tap

Homebrew formulae for [Vigil](https://vigilautonomy.com) — RTK-synchronized
multi-camera capture for autonomous systems.

## Install

```bash
brew install vigilautonomy/tap/vigil
```

This installs the **Vigil console** for Apple Silicon Macs: the `vigil` CLI,
the control-plane API (`:8000`), and the operator UI (`:3000`). Console mode
has no capture — cameras and RTK hardware run on Vigil ground stations
(Ubuntu/Jetson, installed from `apt.vigilautonomy.com`); the console browses
trajectories, runs audits and exports, and drives ground stations remotely.

## Run

```bash
vigil console                  # foreground (Ctrl-C to stop)
brew services start vigil      # background service
```

Then open http://127.0.0.1:3000.

## Upgrade / uninstall

```bash
brew upgrade vigil
brew uninstall vigil           # data in $(brew --prefix)/var/vigil is kept
```

The formula tracks stable releases; it is updated automatically by the Vigil
release pipeline on every tagged release.

> **Status note:** if `brew install` reports a checksum mismatch against a
> `0.0.0` version, the first public release has not been published yet.
