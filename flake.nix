{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    # theme
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
              newimage=$path/''${file:1}
              echo "optimizing $image"
              ${pkgs.pngquant}/bin/pngquant --quality 80-90 -f -o $newimage $image
              oldsize=$(stat --format=%s $image)
              newsize=$(stat --format=%s $newimage)
              pct=$(${pkgs.bc}/bin/bc <<< "scale=1; $newsize * 100 / $oldsize")
              echo "size went from "$(($oldsize / 1024))"KB to "$(($newsize / 1024))"KB ("$pct"% as large as original)"
            done
          '';
          inherit (pkgs.callPackage ./fonts.nix { }) copyFonts linkFonts;
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-08-21";
            src = ./.;
            nativeBuildInputs = [ optimize-images zola ];
            configurePhase = ''
              mkdir -p themes/${themeName}
              cp -r ${theme}/* themes/${themeName}
            '' + copyFonts;
            buildPhase = ''
              optimize-images
              zola build
            '';
            installPhase = "cp -r public $out";
          };
          devShells.default = with pkgs; mkShell {
            packages = [ flyctl optimize-images zola ];
            shellHook = ''
              mkdir -p themes
              ln -snf "${theme}" "themes/${themeName}"
            '' + linkFonts;
          };
          packages.docker =
            let
              site = self'.packages.default;
            in
            pkgs.dockerTools.buildLayeredImage {
              name = site.pname;
              tag = site.version;
              contents = [ site pkgs.caddy ];

              config = {
                Cmd = [ "caddy" ];
              };
            };
        };
    };
}
