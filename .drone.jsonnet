local PROD = 'production';
local STAGE = 'staging';
local NIX = 'nix --extra-experimental-features nix-command --extra-experimental-features flakes';

local Secrets(secrets) = {
  environment: {
    [secret]: { from_secret: std.asciiLower(secret) }
    for secret in secrets
  },
};

local WhenProd(prod) = if prod then {
  event: ['promote'],
  target: [PROD],
} else {
  target: { exclude: [PROD] },
};

local Step(env, name, cmds, extras={}) =
  local prod = env == PROD;
  {
    name: name + ' ' + env,
    image: 'nixos/nix:latest',
    volumes: [
      { name: 'site', path: '/site' },
      { name: 'cache', path: '/nix/store' },
    ],
    commands: cmds,
    when: WhenProd(prod),
  } + extras;

local NixStep(env) =
  local prod = env == PROD;
  local output = if prod then '' else ' .#staging-site';
  Step(env, 'nix build', [
    NIX + ' build' + output,
    'cp -r result/* /site/',
  ]);

local DeployStep(env) =
  local prod = env == PROD;
  local options = if prod then '--prod' else '--alias staging';
  Step(env, 'netlify deploy', [
    NIX + ' profile install nixpkgs#netlify-cli',
    'netlify deploy -d /site --auth $NETLIFY_TOKEN --site $NETLIFY_SITE_ID --message "$DRONE_COMMIT_MESSAGE" ' + options,
  ], Secrets(['NETLIFY_TOKEN', 'NETLIFY_SITE_ID']));

{
  kind: 'pipeline',
  type: 'docker',
  name: 'default',

  volumes: [
    { name: 'site', temp: {} },
    { name: 'cache', host: { path: '/data/cache' } },
  ],

  steps: [
    NixStep(STAGE),
    NixStep(PROD),
    DeployStep(STAGE),
    DeployStep(PROD),
  ],
}
