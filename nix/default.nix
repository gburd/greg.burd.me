{ callPackage }: {
  deploy = { dockerImage }: callPackage ./deploy.nix { inherit dockerImage; };
  docker = { caddyfile, site }: callPackage ./docker.nix { inherit caddyfile site; };
  fonts = callPackage ./fonts.nix { };
  optimize-images = callPackage ./optimize-images.nix { };
  themes = { theme, themeEnabled }: callPackage ./themes.nix { inherit theme themeEnabled; };
}
