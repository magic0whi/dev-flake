{
  description = "My Nix flake managed develop environment";
  inputs = {
    # Align with my nixos-config
    nixpkgs.url = "github:magic0whi/nixpkgs/main";
    # Pinned as of 2026-05-16 00:09
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/790751ff7fd3801feeaf96d7dc416a8d581265ba";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      imports = [
        ./module-args.nix
        ./treefmt.nix
      ];
      perSystem =
        {
          config,
          lib,
          pkgs,
          self',
          system,
          ...
        }:
        let
          import_shell = dir: pkgs.callPackage dir { };
        in
        {
          devShells = {
            default =
              let
                script =
                  name: runtimeInputs: text:
                  pkgs.writeShellApplication { inherit name runtimeInputs text; };
              in
              pkgs.mkShellNoCC {
                name = "Dev-default";
                buildInputs = [
                  (script "build" [ ] (
                    lib.concatLines (
                      map (name: ''
                        echo "Building ${name}"
                        nix build ".#devShells.${system}.${name}"
                      '') (builtins.filter (name: name != "default") (builtins.attrNames self'.devShells))
                    )
                  ))
                  (script "check" [ ] ''
                    nix flake check --no-build
                  '')
                  (script "format" [ ] ''
                    git ls-files '*.nix' | xargs nix fmt
                  '')
                  (script "check-formatting" [ config.treefmt.programs.nixfmt.package ] ''
                    git ls-files '*.nix' | xargs nixfmt --check
                  '')
                ]
                ++ [ self'.formatter ];
              };
            c = import_shell ./c-cpp;
            cpp = self'.devShells.c;
            cuda = (import_shell ./cuda).shell;
            cudaPython313 = pkgs.mkShellNoCC {
              inputsFrom =
                let
                  _cuda = import_shell ./cuda;
                in
                [
                  _cuda.shell
                  (_cuda.cudaPkgs.callPackage ./python {
                    pythonVersion = "3.13";
                    extraPackages = ps: [ ps.vllm ];
                  })
                ];
            };
            latex = import_shell ./latex;
            node = import_shell ./node;
            python = import_shell ./python;
            rust = import_shell ./rust;
          };
        };
    };
}
