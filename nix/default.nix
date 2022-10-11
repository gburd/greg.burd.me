{ callPackage }: {
  fonts = callPackage ./fonts.nix { };
  optimize-images = callPackage ./optimize-images.nix { };
}
