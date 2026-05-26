{
  description = "personal site (greg.burd.me)";

  # Nix is optional. The site builds with just `zola build` on any machine
  # (including Netlify's build image, which ships Zola). The flake exists for
  # local convenience: a dev shell with the right Zola version, image-
  # optimization helpers, and pre-commit hooks.

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { flake-parts
    , pre-commit
    , ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ pre-commit.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { config, pkgs, ... }:
        let
          inherit (pkgs.callPackage ./nix { }) optimize-images update-date;
        in
        {
          pre-commit.settings.hooks = {
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            typos.enable = true;
            typos.excludes = [
              "webp"
              "png"
              "svg"
              "ico"
              "pdf"
              "woff2"
            ];
          };
          devShells.default =
            with pkgs;
            mkShell {
              packages = [
                netlify-cli
                optimize-images
                update-date
                zola
                imagemagick
              ];
              shellHook = ''
                ${config.pre-commit.installationScript}
              '';
            };
        };
    };
}
