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
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (gitignore.lib) gitignoreSource;
          inherit (pkgs.callPackage ./nix { }) fonts optimize-images;
          inherit (fonts) copyFonts linkFonts;
          buildSite = { prod }:
            let
              inherit (pkgs.lib) optionalString;
              ifStaging = optionalString (!prod);
              rev = if (self ? rev) then self.rev else "dirty";
            in
            ''
              optimize-images
              ${ifStaging "BASE_URL=https://${rev}--mat-services.netlify.app"}
              zola build --drafts ${ifStaging "--base-url $BASE_URL"}
              # zola's ignored_content setting doesn't work in static/
              ${ifStaging "cp headers/staging public/_headers"}
              rm -rf public/image/_favicon.svg
            '';
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-10-20";
            src = gitignoreSource ./.;
            nativeBuildInputs = [ optimize-images zola ];
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
