# typed: false
# frozen_string_literal: true

# Stages the download as an opaque file instead of auto-extracting it: the
# tarball bundles delocate-built wheels (av, scipy, ...) whose dylibs have
# zero Mach-O header padding, and Homebrew's post-install linkage fixer
# fails rewriting their IDs. With no Mach-O in the keg at fix time there is
# nothing to rewrite; post_install extracts the payload afterwards and
# bin/vigil-relocate (shipped in the tarball) binds it to the keg path.
class VigilPayloadDownloadStrategy < CurlDownloadStrategy
  def stage(&block)
    UnpackStrategy::Uncompressed.new(cached_location)
                                .extract(basename: basename, verbose: verbose?)
    yield if block
  end
end

# Vigil ground station console for macOS (Apple Silicon).
#
# The url/sha256/version fields are rewritten automatically by the vigil
# repository's release pipeline (bump-tap job) on every tagged release —
# keep each on its own line with double quotes. Until the first release
# publishes, the placeholder sha256 makes `brew install` fail its checksum
# with a clear error rather than installing anything.
class Vigil < Formula
  desc "Vigil ground station console: CLI, control-plane API, and operator UI"
  homepage "https://github.com/VigilAutonomy/vigil"
  version "0.23.1"
  url "https://dl.vigilautonomy.com/macos/vigil-0.23.1-darwin-arm64.tar.gz",
      using: VigilPayloadDownloadStrategy
  sha256 "8259020b7aca91985f1aa6015cc6974b3e233e1c30a73e17bbcaa42f687b8a2c"
  license :cannot_represent

  depends_on arch: :arm64
  depends_on :macos

  def install
    # Self-contained console-mode tarball: bundled CPython + venv +
    # control-plane source + Node runtime + operator UI. No sensor plane —
    # capture runs on Jetson ground stations; this is the operator console.
    libexec.install Dir["vigil-*-darwin-arm64.tar.gz"].fetch(0) => "payload.tar.gz"
    # Data (SQLite DB, logs, exports) must survive upgrades: point the CLI
    # at var instead of the versioned Cellar prefix. The target appears
    # when post_install extracts the payload.
    (bin/"vigil").write_env_script libexec/"bin/vigil", VIGIL_DATA_DIR: var/"vigil"
  end

  def post_install
    # Idempotent: `brew postinstall vigil` after a completed install is a
    # no-op (the payload tarball is consumed on first extraction).
    if (libexec/"payload.tar.gz").exist?
      system "tar", "-xzf", libexec/"payload.tar.gz",
             "-C", libexec, "--strip-components", "1"
      rm libexec/"payload.tar.gz"
    end
    # Bind the bundled venv to this Cellar path (strictly literal rewrite
    # through the bundled interpreter; re-run safe).
    system libexec/"bin/vigil-relocate"
    (var/"vigil").mkpath
    (var/"log").mkpath
  end

  service do
    run [opt_bin/"vigil", "console"]
    working_dir var/"vigil"
    log_path var/"log/vigil-console.log"
    error_log_path var/"log/vigil-console.log"
  end

  def caveats
    <<~EOS
      Run the console in the foreground:
        vigil console
      or as a background service:
        brew services start vigil

      Control plane: http://127.0.0.1:8000   Operator UI: http://127.0.0.1:3000
      Data lives in #{var}/vigil (survives upgrades).

      Console mode has no capture: cameras/RTK run on Vigil ground stations
      (Ubuntu/Jetson, installed via apt.vigilautonomy.com). This console
      browses trajectories, runs audits/exports, and drives stations remotely.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vigil self version")
  end
end
