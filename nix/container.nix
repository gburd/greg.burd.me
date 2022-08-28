{ dockerTools, caddy, caddyfile, site }:

dockerTools.buildLayeredImage {
  name = site.pname;
  tag = site.version;

  config = {
    Cmd = [ "${caddy}/bin/caddy" "run" "-config" "${caddyfile}" ];
    Env = [
      "SITE_ROOT=${site}"
      "LOG_OUTPUT_ADDR=tcp://[fdaa:0:742b:a7b:ab2:1:a2b5:2]:9090"
    ];
  };
}
