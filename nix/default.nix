{ callPackage }: {
  optimize-images = callPackage ./optimize-images.nix { };
  update-date = callPackage ./update-date.nix { };
}
