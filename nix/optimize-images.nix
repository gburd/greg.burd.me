{ bc, imagemagick, libwebp, scour, writeShellScriptBin }:

writeShellScriptBin "optimize-images" ''
  shopt -s globstar nullglob
  ${scour}/bin/scour -i static/image/_favicon.svg -o static/image/favicon.svg
  for image in content/**/_*.png static/image/**/_*.png; do
    path=$(dirname $image)
    file=$(basename -s .png $image)
    newimage=$path/''${file:1}.webp
    echo "optimizing $image"
    ${libwebp}/bin/cwebp -quiet -o $newimage $image
    oldsize=$(stat --format=%s $image)
    newsize=$(stat --format=%s $newimage)
    pct=$(${bc}/bin/bc <<< "scale=1; $newsize * 100 / $oldsize")
    echo "size went from "$(($oldsize / 1024))"KB to "$(($newsize / 1024))"KB ("$pct"% as large as original)"
  done
  ${imagemagick}/bin/convert static/image/favicon.svg -resize 256x256 static/favicon.ico
''
