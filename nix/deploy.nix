{ lib, docker, flyctl, formats, writeShellScriptBin, dockerImg }:

writeShellScriptBin "deploy" ''
  set -euxo pipefail
  export PATH="${lib.makeBinPath [(docker.override { clientOnly = true; }) flyctl]}:$PATH"
  archive=${dockerImg}
  image=$(docker load < $archive | awk '{ print $3; }')
  flyctl deploy -i $image
''
