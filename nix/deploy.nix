{ lib, docker, flyctl, formats, writeShellScriptBin, dockerImage }:

writeShellScriptBin "deploy" ''
  set -euxo pipefail
  export PATH="${lib.makeBinPath [(docker.override { clientOnly = true; }) flyctl]}:$PATH"
  archive=${dockerImage}
  # load archive, drop all output except last line (in case of warnings), print image name
  image=$(docker load < $archive | tail -n1 | awk '{ print $3; }')
  flyctl deploy --image $image --local-only
''
