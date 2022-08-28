{ dockerTools, caddy, caddyfile, site }:

dockerTools.buildLayeredImage {
  name = site.pname;
  tag = site.version;

  config = {
    Cmd = [ "${caddy}/bin/caddy" "run" "-config" "${caddyfile}" ];
    Env = [
      "SITE_ROOT=${site}"
    ];
  };
}
