{ fetchFromGitHub
, lib
, stdenv
, woff2
, writeText
}:
let
  pathName = name: with lib; replaceStrings [ " " ] [ "-" ] (toLower name);
in
rec {
  fontSrcs = [
    {
      name = "Inria Sans";
      fileName = "InriaSans";
      owner = "BlackFoundryCom";
      repo = "InriaFonts";
      rev = "v1.200";
      path = "fonts/InriaSans/Web";
      sha256 = "+YK03VnMXytTtHHgGYe2uARaTThaqrhpnhxPASBV9k0=";
      cssVar = "header-font";
    }
    {
      name = "iA Writer Quattro";
      fileName = "iAWriterQuattroS";
      owner = "iaolo";
      repo = "iA-Fonts";
      rev = "ba31f88a1e71f413f97bbd23a99e21b29d4c3a28";
      path = "iA\ Writer\ Quattro/Webfonts";
      sha256 = "8r06oRA+XA8mPjG3DJxzIVpaqptSqzraOWVvebbnMWE=";
      cssVar = "text-font";
    }
    {
      name = "IBM Plex Mono";
      fileName = "IBMPlexMono";
      owner = "IBM";
      repo = "plex";
      rev = "v6.1.0";
      path = "IBM-Plex-Mono/fonts/complete/woff2";
      sha256 = "SpH4+ldQJl58w5onxr7faDS6uVJKT8ZeLmE6712GFhw=";
      cssVar = "code-font";
    }
  ];
  fontDerivation = { name, owner, repo, rev, sha256, path, ... }: stdenv.mkDerivation {
    name = "font-${pathName name}";
    src = fetchFromGitHub {
      inherit owner repo rev sha256;
      sparseCheckout = [ path ];
    };
    nativeBuildInputs = [ woff2 ];
    buildPhase = ''
      find . -name '*.ttf' -exec woff2_compress {} \;
    '';
    installPhase = ''
      mkdir -p $out
      find . -name '*.woff2' -exec cp {} $out \;
    '';
  };
  fetchFont = fontSrc: {
    inherit (fontSrc) name fileName cssVar;
    font = fontDerivation fontSrc;
  };
  fonts = map fetchFont fontSrcs;
  mkFontCss = { name, fileName, cssVar, ... }:
    let path = pathName name; in ''
      @font-face {
        font-family: '${name}';
        font-style: normal;
        font-weight: normal;
        src: url('../font/${path}/${fileName}-Regular.woff2'), local('woff2');
        font-display: swap;
      }

      @font-face {
        font-family: '${name}';
        font-style: normal;
        font-weight: bold;
        src: url('../font/${path}/${fileName}-Bold.woff2'), local('woff2');
        font-display: swap;
      }

      @font-face {
        font-family: '${name}';
        font-style: italic;
        font-weight: normal;
        src: url('../font/${path}/${fileName}-Italic.woff2'), local('woff2');
        font-display: swap;
      }

      @font-face {
        font-family: '${name}';
        font-style: italic;
        font-weight: bold;
        src: url('../font/${path}/${fileName}-BoldItalic.woff2'), local('woff2');
        font-display: swap;
      }
  
      :root {
        --${cssVar}: '${name}'
      }

    '';
  fontCss = lib.concatMapStrings mkFontCss fonts;
  fontCssFile = writeText "fonts.css" fontCss;
  copyFont = { font, name, ... }:
    let path = pathName name; in ''
      mkdir -p static/font/${path}
      cp -r ${font}/* static/font/${path}
    '';
  copyFonts = (lib.concatMapStrings copyFont fonts) + ''
    mkdir -p static/style
    cp ${fontCssFile} static/style/fonts.css
  '';
  linkFont = { font, name, ... }: ''
    ln -snf "${font}" static/font/${pathName name}
  '';
  linkFonts = ''
    mkdir -p static/font
  '' + (lib.concatMapStrings linkFont fonts) + ''
    mkdir -p static/style
    ln -sf ${fontCssFile} static/style/fonts.css
  '';
}
