{ lib, theme, themeEnabled }:
let
  themeName = ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
in
{
  copyTheme = lib.optionalString themeEnabled ''
    mkdir -p themes/${themeName}
    cp -r ${theme}/* themes/${themeName}
  '';
  linkTheme = lib.optionalString themeEnabled ''
    mkdir -p themes
    ln -snf "${theme}" "themes/${themeName}"
  '';
}
