local Volume = { name: 'site', path: '/site' };
local NetlifyStep(env) =
  local prod = env == 'production';
  {
    name: 'netlify deploy ' + env,
    image: 'internetmat/drone-netlify',
    volumes: [Volume],
    settings: {
      token: { from_secret: 'netlify_token' },
      site: { from_secret: 'netlify_site_id' },
      path: '/site',
      prod: prod,
    },
    when: if prod then {
      event: ['promote'],
      target: ['production'],
    } else {
      target: { exclude: ['production'] },
    },
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
    {
      name: 'nix build',
      image: 'nixos/nix',
      volumes: [Volume],
      commands: [
        '$NIX build',
        'cp -r result/* /site/',
      ],
    },
    NetlifyStep('staging'),
    NetlifyStep('production'),
  ],
}
