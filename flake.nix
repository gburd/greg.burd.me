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
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          optimize-images = pkgs.writeShellScriptBin "optimize-images" ''
            shopt -s globstar nullglob
            ${pkgs.scour}/bin/scour -i static/image/_favicon.svg -o static/image/favicon.svg
            for image in content/**/_*.png static/image/**/_*.png; do
              path=$(dirname $image)
              file=$(basename $image)
              ${pkgs.pngquant}/bin/pngquant --quality 90-99 -f -o "$path/''${file:1}" $image
            done
          '';
        in
        {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "personal-site";
          version = "2022-08-13";
          src = ./.;
            nativeBuildInputs = with pkgs; [ optimize-images zola ];
          configurePhase = ''
            mkdir -p "themes/${themeName}"
            cp -r ${theme}/* "themes/${themeName}"
              optimize-images
          '';
          buildPhase = "zola build";
          installPhase = "cp -r public $out";
        };
          devShells.default = with pkgs; mkShell {
            packages = [ optimize-images flyctl zola ];
          shellHook = ''
            mkdir -p themes
              ln -snf "${theme}" "themes/${themeName}"
          '';
        };
      };
    };
}
