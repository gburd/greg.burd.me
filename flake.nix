{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";

    caddyfile-syntax.url = "github:caddyserver/sublimetext";
    caddyfile-syntax.flake = false;
  };

  outputs = { self, flake-parts, gitignore, ... }@inputs:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (gitignore.lib) gitignoreSource;
          inherit (pkgs.callPackage ./nix { }) fonts optimize-images update-date;
          inherit (fonts) copyFonts linkFonts;
          caddyfile-syntax = "${inputs.caddyfile-syntax}/Caddyfile.sublime-syntax";
          buildSite = { prod }:
            let
              inherit (pkgs.lib) optionalString;
              ifStaging = optionalString (!prod);
              rev = if (self ? rev) then self.rev else "dirty";
            in
            ''
              optimize-images
              zola build --drafts ${ifStaging "--base-url https://staging--mat-services.netlify.app"}
              # zola's ignored_content setting doesn't work in static/
              rm -rf public/image/_favicon.svg
              cp public/image/favicon.svg public/favicon.svg
            '';
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-10-23";
            src = gitignoreSource ./.;
            nativeBuildInputs = [ optimize-images update-date zola ];
            configurePhase = copyFonts + ''
              mkdir -p extra/syntax
              cp ${caddyfile-syntax} extra/syntax
            '';
            buildPhase = buildSite { prod = true; };
            installPhase = ''
              cp -r public $out
            '';
          };
          packages.staging-site = config.packages.default.overrideAttrs (_: {
            buildPhase = buildSite { prod = false; };
          });
          devShells.default = with pkgs; mkShell {
            packages = [ optimize-images update-date zola ];
            shellHook = linkFonts + ''
              mkdir -p extra/syntax
              ln -snf ${caddyfile-syntax} extra/syntax
            '';
          };
        };
    };
}
