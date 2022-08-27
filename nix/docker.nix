{ dockerTools, caddy, site }:

dockerTools.buildLayeredImage {
  name = site.pname;
  tag = site.version;
  contents = [ site caddy ];

  config = {
    Cmd = [ "${caddy}/bin/caddy" "run" "-config" "${site}/Caddyfile" ];
  };
}
