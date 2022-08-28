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
          # TODO: move these to a flake-modules
          inherit (pkgs.callPackage ./nix { }) container deploy fonts optimize-images themes;
          inherit (fonts) copyFonts linkFonts;
          inherit (themes {
            theme = inputs.apollo;
            themeEnabled = false;
          }) copyTheme linkTheme;
        in
        {
          packages.default = with pkgs; stdenv.mkDerivation {
            pname = "personal-site";
            version = "2022-08-27";
            src = ./.;
            nativeBuildInputs = [ optimize-images zola ];
            configurePhase = copyTheme + copyFonts;
            buildPhase = ''
              optimize-images
              zola build --drafts
            '';
            installPhase = ''
              cp -r public $out
            '';
          };
          devShells.default = with pkgs; mkShell {
            packages = [ flyctl optimize-images zola ];
            shellHook = linkTheme + linkFonts;
          };
          packages.container = container {
            caddyfile = builtins.readFile ./Caddyfile;
            site = config.packages.default;
          };
          apps.deploy.program =
            let deploy' = deploy { dockerImage = config.packages.container; };
            in "${deploy'}/bin/deploy";
        };
    };
}
