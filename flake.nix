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
          buildSite = { prod }:
            let inherit (pkgs.lib) optionalString; in ''
              optimize-images
              ${optionalString (!prod) "BASE_URL=https://$DRONE_COMMIT_SHA--mat-services.netlify.app"}
              zola build --drafts ${optionalString (!prod) "--base-url $BASE_URL"}
              # zola's ignored_content setting doesn't work in static/
              rm -rf public/image/_favicon.svg
            '';
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-10-10";
            src = gitignoreSource ./.;
            nativeBuildInputs = [ git optimize-images zola ];
            configurePhase = copyFonts;
            buildPhase = buildSite { prod = true; };
            installPhase = ''
              cp -r public $out
            '';
          };
          packages.staging-site = config.packages.default.overrideAttrs (_: {
            buildPhase = buildSite { prod = false; };
          });
          devShells.default = with pkgs; mkShell {
            packages = [ optimize-images zola ];
            shellHook = linkFonts;
          };
        };
    };
}
