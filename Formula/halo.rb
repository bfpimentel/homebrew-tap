class Halo < Formula
  desc "Widget runtime for macOS: bars, panels and HUDs written in TSX"
  homepage "https://github.com/bfpimentel/halo"
  # The halo release workflow updates url and sha256.
  url "https://github.com/bfpimentel/halo/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "c73f4bdd2cc94aff7dd4d8278d19b46c12584b7a86b850338409d7457b86998f"
  license "GPL-3.0-or-later"
  head "https://github.com/bfpimentel/halo.git", branch: "main"

  depends_on xcode: ["16.0", :build]
  depends_on "esbuild"
  depends_on macos: :sonoma

  def install
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
