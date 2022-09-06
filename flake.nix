{
  description = "personal site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";

    # theme - inlined now, not used
    apollo.url = "github:not-matthias/apollo";
    apollo.flake = false;
  };

  outputs = { self, flake-parts, gitignore, ... }@inputs:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [ ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (gitignore.lib) gitignoreSource;
          # TODO: move these to a flake-module
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
            version = "2022-09-06";
            src = gitignoreSource ./.;
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
            caddyfile = ./Caddyfile;
            site = config.packages.default;
          };
          apps.deploy.program =
            let deploy' = deploy { dockerImage = self.packages.x86_64-linux.container; };
            in "${deploy'}/bin/deploy";
        };
    };
}
