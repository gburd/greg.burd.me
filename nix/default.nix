{ callPackage }: {
  container = { caddyfile, site }: callPackage ./container.nix { inherit caddyfile site; };
  deploy = { dockerImage }: callPackage ./deploy.nix { inherit dockerImage; };
  fonts = callPackage ./fonts.nix { };
  optimize-images = callPackage ./optimize-images.nix { };
  themes = { theme, themeEnabled }: callPackage ./themes.nix { inherit theme themeEnabled; };
}
