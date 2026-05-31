{ pkgs, ... }:
let
  _pkgs = pkgs.extend (
    _final: prev: rec {
      nodejs = prev.nodejs;
      yarn = prev.yarn.override { inherit nodejs; };
    }
  );
in
_pkgs.mkShellNoCC {
  name = "Node.js";
  buildInputs = with pkgs; [
    nodejs
    pnpm
    yarn
    bun
    typescript-language-server
  ];
  shellHook = ''
    echo "node `node --version`"
  '';
}
