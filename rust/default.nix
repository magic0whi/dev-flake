{
  pkgs,
  system,
  prince-213-nix-packages,
  ...
}:
(pkgs.mkShellNoCC.override
  {
    # Override stdenv to change compiler:
    # stdenv = pkgs.clangStdenv;
  }
  {
    name = "Rust";
    nativeBuildInputs = with pkgs; [
      pkg-config
      webkitgtk_4_1
      openssl # Required by openssl-sys
      # wrapGAppsHook4
      # cargo-tauri
      # rustc
    ];
    buildInputs = with pkgs; [
      cargo
      rustc
      # librsvg
      # gtk3
      # pango # Fixes the missing pango error
      # cairo
      # gdk-pixbuf
      prince-213-nix-packages.packages.${system}.kodama
    ];
    shellHook = ''
      rustc --version && cargo --version
    '';
  }
)
