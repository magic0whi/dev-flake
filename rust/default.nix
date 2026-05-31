{ pkgs, ... }:
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
    ];
    shellHook = ''
      rustc --version && cargo --version
    '';
  }
)
