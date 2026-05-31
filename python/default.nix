{
  pkgs,
  pythonVersion ? "3.14",
  extraPackages ? (_ps: [ ]),
  ...
}:
let
  # Change this value ({major}.{min}) to update the Python virtual-environment version. When you do this, make sure to
  # delete the `.venv` directory to have the hook rebuild it for the new version, since it won't overwrite an existing
  # one. After this, reload the development shell to rebuild it. You'll see a warning asking you to do this when version
  # mismatches are present. For safety, removal should be a manual step, even if trivial.
  version = pythonVersion;
  py_package =
    let
      # Construct a function to concatenate marjor and minor versions
      # nixpkgs doesn't have patch version included for package naming suffix
      serialize_ver =
        ver:
        pkgs.lib.pipe ver [
          # Pipe these three funcs
          pkgs.lib.versions.splitVersion # e.g. 3.13.1 -> ["3" "13" "1"]
          (pkgs.lib.sublist 0 2) # e.g. ["3" "13" "1"] -> ["3" "13"]
          pkgs.lib.concatStrings # e.g. ["3" "13"] -> "313"
        ];
    in
    pkgs."python${serialize_ver version}";
in
pkgs.mkShellNoCC {
  name = "Python";
  shellHook = ''
    python --version
  '';
  venvDir = ".venv";
  postShellHook = ''
    venvVersionWarn() {
      local venvVersion
      venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

      [[ "$venvVersion" == "${py_package.version}" ]] && return

      cat <<EOF
      Warning: Python version mismatch: [$venvVersion (venv)] != [${py_package.version}]
      Delete '$venvDir' and reload to rebuild for version ${py_package.version}
      EOF
    }
    venvVersionWarn
  '';
  nativeBuildInputs = with py_package.pkgs; [
    requests
    paramiko
    scp
    chardet
    pyyaml
    ruamel-yaml
    flask # sing-box-subscribe
    pytesseract
  ];

  buildInputs =
    with py_package.pkgs;
    [
      venvShellHook
      pip
      uv

      ty
      python-lsp-server
      ruff

      fava
      fava-dashboards
    ]
    ++ extraPackages py_package.pkgs;
}
