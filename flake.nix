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
          version = "2022-08-13";
          src = ./.;
          nativeBuildInputs = with pkgs; [ pngquant scour zola ];
          configurePhase = ''
            mkdir -p "themes/${themeName}"
            cp -r ${theme}/* "themes/${themeName}"
            scour -i static/image/_favicon.svg -o static/image/favicon.svg
            for image in content/**/_*.png static/image/**.png; do
              path=$(dirname $image)
              file=$(basename $image)
              pngquant --quality 90-99 -f -o "$path/''${file:1}"
            done
          '';
          buildPhase = "zola build";
          installPhase = "cp -r public $out";
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ zola ];
          shellHook = ''
            mkdir -p themes
            ln -sn "${theme}" "themes/${themeName}"
          '';
        };
      };
    };
}
