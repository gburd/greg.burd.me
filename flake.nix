{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-parts, gitignore, ... }@inputs:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (gitignore.lib) gitignoreSource;
          inherit (pkgs.callPackage ./nix { }) fonts optimize-images;
          inherit (fonts) copyFonts linkFonts;
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-10-10";
            src = gitignoreSource ./.;
            nativeBuildInputs = [ optimize-images zola ];
            configurePhase = copyFonts;
            buildPhase = ''
              optimize-images
              zola build --drafts
              # zola's ignored_content setting doesn't work in static/
              rm -rf public/image/_favicon.svg
            '';
            installPhase = ''
              cp -r public $out
            '';
          };
          packages.staging-site = config.packages.default.overrideAttrs (_: {
            buildPhase = ''
              optimize-images
              zola build --drafts --base_url $DEPLOY_PRIME_URL
              # zola's ignored_content setting doesn't work in static/
              rm -rf public/image/_favicon.svg
            '';
          });
          devShells.default = with pkgs; mkShell {
            packages = [ optimize-images zola ];
            shellHook = linkFonts;
          };
        };
    };
}
