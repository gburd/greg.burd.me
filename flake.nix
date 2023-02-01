{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.inputs.gitignore.follows = "gitignore";

    caddyfile-syntax.url = "github:caddyserver/sublimetext";
    caddyfile-syntax.flake = false;
  };

  outputs = { self, flake-parts, gitignore, pre-commit, ... }@inputs:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ pre-commit.flakeModule ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, pkgs, ... }:
        let
          inherit (gitignore.lib) gitignoreSource;
          inherit (pkgs.callPackage ./nix { }) fonts optimize-images update-date;
          inherit (fonts) copyFonts linkFonts;
          caddyfile-syntax = "${inputs.caddyfile-syntax}/Caddyfile.sublime-syntax";
          buildSite = { prod }:
            let
              ifStaging = pkgs.lib.optionalString (!prod);
            in
            ''
              optimize-images
              zola build --drafts ${ifStaging "--base-url https://staging--mat-services.netlify.app"}
              # zola's ignored_content setting doesn't work in static/
              rm -rf public/image/_favicon.svg
            '';
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2023-02-01";
            src = gitignoreSource ./.;
            nativeBuildInputs = [ optimize-images update-date zola ];
            configurePhase = ''
              ${copyFonts}
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
          pre-commit.settings.hooks = {
            # nix hooks
            deadnix.enable = true;
            nix-linter.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            # general hooks
            typos.enable = true;
            typos.excludes = [ "webp" "png" "svg" "ico" ];
          };
          devShells.default = with pkgs; mkShell {
            packages = [ jsonnet netlify-cli optimize-images update-date zola ];
            shellHook = ''
              ${config.pre-commit.installationScript}
              ${linkFonts}
              mkdir -p extra/syntax
              ln -snf ${caddyfile-syntax} extra/syntax
            '';
            inputsFrom = builtins.attrValues self.checks;
          };
        };
    };
}
