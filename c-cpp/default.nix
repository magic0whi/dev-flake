{ pkgs, lib, ... }:
(pkgs.mkShellNoCC.override
  {
    # Override stdenv to change compiler:
    # stdenv = pkgs.clangStdenv;
  }
  {
    name = "CPP";
    buildInputs =
      with pkgs;
      [
        llvmPackages.clangUseLLVM
        llvmPackages.bintools
        clang-tools
        cmake
        ninja
        # codespell
        # conan
        # cppcheck
        # doxygen
        # gtest
        # lcov
        # vcpkg
        # vcpkg-tool
      ]
      ++ lib.optional (!stdenv.hostPlatform.isDarwin) [ gdb ];
    shellHook = ''
      echo "------ clang -----";
      cc --version
      echo "------ ld ------"
      ld -v
    '';
  }
)
