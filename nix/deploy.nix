{ lib, docker, flyctl, formats, writeShellScriptBin, dockerImage }:

writeShellScriptBin "deploy" ''
  set -euxo pipefail
  export PATH="${lib.makeBinPath [(docker.override { clientOnly = true; }) flyctl]}:$PATH"
  archive=${dockerImage}
  image=$(docker load < $archive | awk '{ print $3; }')
  flyctl deploy -i $image
''
