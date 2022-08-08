{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    apollo.url = "github:not-matthias/apollo";
    apollo.flake = false;
  };

  outputs = { self, flake-parts, ... }@inputs:
    let
      theme = inputs.apollo;
      themeName = ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
    in
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "personal-site";
          version = "2022-08-07";
          src = ./.;
          nativeBuildInputs = [ pkgs.zola ];
          configurePhase = ''
            mkdir -p "themes/${themeName}"
            cp -r ${theme}/* "themes/${themeName}"
          '';
          buildPhase = "zola build";
          installPhase = "cp -r public $out";
        };
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.zola ];
          shellHook = ''
            mkdir -p themes
            ln -sn "${theme}" "themes/${themeName}"
          '';
        };
      };
    };
}
