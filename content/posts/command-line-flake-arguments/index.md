+++
title = "passing command line arguments to nix flakes"
date = "2022-09-20"
description = "a tutorial on 'breaking' the hermeticity of nix flakes by adding convenient command line flags"
draft = true
[taxonomies]
tags = ["nix"]
[extra]
hero = true
+++

<figure>
<img class="hero" alt="A rogue program hacking through the firewall, in the style of Tron Legacy, cyberpunk vibe, digital render, 8k uhd, unreal engine - generated using Stable Diffusion" src=hero.png />
<figcaption><h4><i>A rogue program hacking through the firewall, in the style of Tron Legacy, cyberpunk vibe, digital render, 8k uhd, unreal engine</i> - generated using Stable Diffusion</h4></figcaption>
</figure>

[Nix flakes](https://serokell.io/blog/practical-nix-flakes) are very useful, but the feature of a fully hermetic build also means that they carry with them a certain degree of inflexibility. [Users have asked for a mechanism to parameterize flakes](https://github.com/NixOS/nix/issues/2861#issuecomment-891521971), but there seems to be no interest from the Nix maintainers in adding such a feature.

From the outside, a flake is black box, a function from its input sources to the artifacts that it outputs. There is no built-in way to pass a boolean flag, or string, from the command line in order to override a deeply nested configuration. In most cases, this is fine, and you can work around many apparent needs for a one off override by building separate outputs for different purposes.

A real-life use case where a command line override would come in handy is my own nix-darwin configuration, where I have my homebrew formulas and casks specified. I like to let Nix manage installing and upgrading these packages, but unfortunately the process to check for updates eats up a bit of time. When I'm testing a new change to some other part of my nix-darwin setup, I don't like to waste time repeatedly checking for homebrew updates. I could manually disable homebrew updates, but then I have to remember to flip it back on. How nice would it be to have two commands? Something like:
```bash
# rebuild the full system flake, when we want to perform homebrew updates
darwin-rebuild switch --flake <flake-path>
# rebuild without homebrew, for testing changes more quickly
darwin-rebuild switch --flake <flake-path> --no-homebrew
```

## (Ab)using Nix flake inputs to pass overrides
As mentioned before, flakes are a black box function from their (aptly named) inputs to their outputs. Typically, our inputs are Nix expressions or source code that we want to use in our flake, but they can be used to smuggle in any old source code tree we want. What if we parameterized our flake with a special source input?

While Nix has no generalized mechanism for command line overrides to flakes, there is a mechanism *for overriding flake inputs*: combine that with an input that we use for the special purpose of gating a feature or setting a value, and we have what we wanted.

### Command line flags for flakes
I have totally lost track of my initial encounter with this method, but at some point I came across the [`boolean-option`](https://github.com/boolean-option) Github account that includes two repositories of interest: `true` and `false`. Upon inspection, each repo includes a trivial flake with a single output `value`, a boolean Nix value that matches the name of the repo. You can add a command line flag with a desired default value like so:
```nix
{
  inputs = {
    my-flag.url = "github:boolean-option/true";
  };
  outputs = { self, my-flag }: {
    message = if my-flag.value
      then "it's good!"
      else "it's bad..";
  };
}
```

Now you can build this flake and control the output message from the command line:
```bash
nix eval --raw '.#message'
"it's good!"

nix eval --override-input my-flag github:boolean-option/false --raw '.#message'
"it's bad.."
```

So far, every flake-oriented Nix command I have tried supports the `override-input` flag, so this is a pretty reliable mechanism for passing in overrides where needed.

[Take a look at how I use this in my own system flake.](https://git.mat.services/mat/dotfiles.nix/src/branch/main/flake.nix#L256)

## Acknowledgements
Thank you to [Rahul Butani](https://github.com/rrbutani), the creator of the `boolean-option` Github account!
