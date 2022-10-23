{ coreutils, sd, writeShellScriptBin }:

writeShellScriptBin "update-date" ''
  export VERSION=$1
  if [ -z "$VERSION" ]
  then
    export VERSION=$(${coreutils}/bin/date -I)
  fi
  ${sd}/bin/sd 'version = ".*"' 'version = "'$VERSION'"' flake.nix
''
