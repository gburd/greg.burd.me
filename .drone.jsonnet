local Volume = { name: 'site', path: '/site' };
local WhenProd(prod) = if prod then {
  event: ['promote'],
  target: ['production'],
} else {
  target: { exclude: ['production'] },
};
local NixStep(env) =
  local prod = env == 'production';
  local output = if prod then '' else ' .#staging-site';
  {
    name: 'nix build ' + env,
    image: 'nixos/nix:latest',
    volumes: [Volume],
    commands: [
      '$NIX build' + output,
      'cp -r result/* /site/',
    ],
    when: WhenProd(prod),
  };
local NetlifyStep(env) =
  local prod = env == 'production';
  {
    name: 'netlify deploy ' + env,
    image: 'internetmat/drone-netlify:latest',
    pull: 'always',
    volumes: [Volume],
    settings: {
      token: { from_secret: 'netlify_token' },
      site: { from_secret: 'netlify_site_id' },
      alias: env,
      path: '/site',
      prod: prod,
    },
    when: WhenProd(prod),
  };
{
  kind: 'pipeline',
  type: 'docker',
  name: 'default',

  environment: {
    NIX: 'nix --extra-experimental-features nix-command --extra-experimental-features flakes',
  },

  volumes: [{ name: 'site', temp: {} }],

  steps: [
    NixStep('staging'),
    NixStep('production'),
    NetlifyStep('staging'),
    NetlifyStep('production'),
  ],
}
