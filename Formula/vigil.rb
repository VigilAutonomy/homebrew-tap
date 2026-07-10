# typed: false
# frozen_string_literal: true

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
  version "0.0.0"
  url "https://dl.vigilautonomy.com/macos/vigil-0.0.0-darwin-arm64.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license :cannot_represent

  depends_on arch: :arm64
  depends_on :macos

  def install
    # Self-contained console-mode tarball: bundled CPython + venv +
    # control-plane source + Node runtime + operator UI. No sensor plane —
    # capture runs on Jetson ground stations; this is the operator console.
    libexec.install Dir["*"]
    # Bind the bundled venv to this Cellar path (strictly literal rewrite
    # through the bundled interpreter; re-run safe).
    system libexec/"bin/vigil-relocate"
    # Data (SQLite DB, logs, exports) must survive upgrades: point the CLI
    # at var instead of the versioned Cellar prefix.
    (bin/"vigil").write_env_script libexec/"bin/vigil", VIGIL_DATA_DIR: var/"vigil"
  end

  def post_install
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
