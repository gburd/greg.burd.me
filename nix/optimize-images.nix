{ bc, pngquant, scour, writeShellScriptBin }:

writeShellScriptBin "optimize-images" ''
  shopt -s globstar nullglob
  ${scour}/bin/scour -i static/image/_favicon.svg -o static/image/favicon.svg
  for image in content/**/_*.png static/image/**/_*.png; do
    path=$(dirname $image)
    file=$(basename $image)
    newimage=$path/''${file:1}
    echo "optimizing $image"
    ${pngquant}/bin/pngquant --quality 70-90 -f -o $newimage $image
    oldsize=$(stat --format=%s $image)
    newsize=$(stat --format=%s $newimage)
    pct=$(${bc}/bin/bc <<< "scale=1; $newsize * 100 / $oldsize")
    echo "size went from "$(($oldsize / 1024))"KB to "$(($newsize / 1024))"KB ("$pct"% as large as original)"
  done
''
