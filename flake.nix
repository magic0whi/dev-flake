{
  description = "My Nix flake managed develop environment";
  inputs = {
    # Align with my nixos-config
    nixpkgs.url = "github:magic0whi/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/0d6d739a833ba9a9c93034862e4a7b061a062a1c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts/ea2630b7470978622c7689a1ff75d2b389175399";
    # devenv.url = "github:cachix/devenv/21d68a204558895af93ad82014f8fa83f9c9a51e";
    prince-213-nix-packages.url = "github:Prince213/nix-packages";
  };
  # nixConfig = {
  #   extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  #   extra-substituters = "https://devenv.cachix.org";
  # };
  outputs =
    inputs@{
      flake-parts,
      # devenv,
      ...
    }:
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
          callPackage = pkgs.callPackage;
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
            c = callPackage ./c-cpp { };
            cpp = self'.devShells.c;
            cuda = (callPackage ./cuda { }).shell;
            cudaPython313 = pkgs.mkShellNoCC {
              inputsFrom =
                let
                  _cuda = callPackage ./cuda { };
                in
                [
                  _cuda.shell
                  (_cuda.cudaPkgs.callPackage ./python {
                    pythonVersion = "3.13";
                    extraPackages = _ps: [
                      # ps.vllm
                    ];
                  })
                ];
            };
            latex = callPackage ./latex {
              inherit system;
              inherit (inputs) prince-213-nix-packages;
            };
            node = callPackage ./node { };
            python = callPackage ./python { };
            rust = callPackage ./rust { };
            # devenv = devenv.lib.mkShell {
            #   inherit inputs pkgs;
            #   modules = [
            #     (
            #       { pkgs, ... }:
            #       {
            #         packages = [ pkgs.hello ];
            #         enterShell = ''
            #           hello
            #         '';
            #         processes.run.exec = "hello";
            #         files."tex-fmt.toml".toml = {
            #           wraplen = 120;
            #           wrapmin = 120;
            #           # format-tables = true
            #         };
            #       }
            #     )
            #   ];
            # };
          };
        };
    };
}
