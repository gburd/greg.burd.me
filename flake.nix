{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    # theme - inlined now, not used
    apollo.url = "github:not-matthias/apollo";
    apollo.flake = false;
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (pkgs) callPackage;
          optimize-images = callPackage ./nix/optimize-images.nix { };
          inherit (callPackage ./nix/fonts.nix { }) copyFonts linkFonts;
          inherit (callPackage ./nix/theme.nix {
            theme = inputs.apollo;
            themeEnabled = false;
          }) copyTheme linkTheme;
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-08-21";
            src = ./.;
            nativeBuildInputs = [ optimize-images zola ];
            configurePhase = copyTheme + copyFonts;
            buildPhase = ''
              optimize-images
              zola build
            '';
            installPhase = ''
              cp -r public $out
              cp Caddyfile $out
            '';
          };
          devShells.default = with pkgs; mkShell {
            packages = [ flyctl optimize-images zola ];
            shellHook = linkTheme + linkFonts;
          };
          packages.docker = callPackage ./nix/docker.nix { site = self'.packages.default; };
          apps.deploy.program =
            let deploy = callPackage ./nix/deploy.nix { dockerImg = self'.packages.docker; };
            in "${deploy}/bin/deploy";
        };
    };
}
