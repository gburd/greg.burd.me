local PROD = 'production';
local STAGE = 'staging';
local VOLUME = { name: 'site', path: '/site' };
local NIX = 'nix --extra-experimental-features nix-command --extra-experimental-features flakes';

local WhenProd(prod) = if prod then {
  event: ['promote'],
  target: [PROD],
} else {
  target: { exclude: [PROD] },
};

local Step(env, name, cmds) =
  local prod = env == PROD;
  {
    name: name + ' ' + env,
    image: 'nixos/nix:latest',
    volumes: [VOLUME],
    commands: cmds,
    when: WhenProd(prod),
  };

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
    NIX + ' profile install nixgpkgs#netlify-cli',
    'netlify deploy -d /site ' + options,
  ]);

{
  kind: 'pipeline',
  type: 'docker',
  name: 'default',

  volumes: [{ name: 'site', temp: {} }],

  steps: [
    NixStep(STAGE),
    NixStep(PROD),
    DeployStep(STAGE),
    DeployStep(PROD),
  ],
}
