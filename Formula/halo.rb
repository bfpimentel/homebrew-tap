class Halo < Formula
  desc "Widget runtime for macOS: bars, panels and HUDs written in TSX"
  homepage "https://github.com/bfpimentel/halo"
  # The halo release workflow updates url and sha256.
  url "https://github.com/bfpimentel/halo/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "c673ac08f682c413c73fc3dded4b52143aadd54af5a65472870e23e0d8f433dc"
  license "GPL-3.0-or-later"
  head "https://github.com/bfpimentel/halo.git", branch: "main"

  depends_on xcode: ["16.0", :build]
  depends_on "esbuild"
  depends_on macos: :sonoma

  def install
    # halo's source says "dev"; the version lives in the git tag (HEAD-<sha> for --HEAD). Tags before 0.5 already
    # carry it in source, so a missing match is fine.
    inreplace "Sources/IPC/Protocol.swift", 'static let version = "dev"',
              "static let version = \"#{version}\"", audit_result: false
    system "swift", "build", "--disable-sandbox", "--configuration", "release", "--product", "halo"
    bin.install ".build/release/halo"
    # Bundler looks for <prefix>/share/halo/runtime/src next to the real binary.
    (pkgshare/"runtime").install "runtime/src"
    pkgshare.install "examples"
  end

  service do
    run [opt_bin/"halo", "start"]
    # `halo quit` and a missing config exit normally and stay stopped; only crashes restart it.
    keep_alive crashed: true
    process_type :interactive
    environment_variables PATH: std_service_path_env
    log_path var/"log/halo.log"
    error_log_path var/"log/halo.log"
  end

  def caveats
    <<~EOS
      Create a config (starter widget + editor types) in ~/.config/halo:
        halo init

      Run it at login:
        brew services start halo

      Examples live in:
        #{opt_pkgshare}/examples
    EOS
  end

  test do
    assert_match "halo #{version.head? ? "" : version}", shell_output("#{bin}/halo --version")
    system bin/"halo", "init", testpath/"config"
    assert_path_exists testpath/"config/main.tsx"
    assert_match "share/halo/runtime/src", (testpath/"config/tsconfig.json").read
  end
end
