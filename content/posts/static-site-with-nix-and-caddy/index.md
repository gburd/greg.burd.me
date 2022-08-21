+++
title = "hosting a static site on fly.io with nix and caddy"
date = "2022-08-20"
draft = true
[taxonomies]
tags = ["static-site", "nix", "caddy", "fly.io"]
+++

## Motivation
So, [you've ditched Github and friends](https://sfconservancy.org/GiveUpGitHub/), [set up your own Gitea instance](./gitea-on-fly-io), and there's just one (read: at least one) thing left for you to take care of—that snazzy static site you had up on Github Pages.

### Pages and Static Site Hosting
I can remember how empowering it felt when I finally realized how much utility Github had packed into the Pages product. I went through a gleeful week or more of churning out Vue.js templates and half-baked styles for several different sites, all the while starry-eyed with how easy Pages made the deployment process. Eventually I migrated some of my work, including my static sites, to Gitlab, which has a virtually identical offering. I was quietly pleased with the ease of use afforded by both options.

Fast forward to today, and my migration away from Github and Gitlab has me once again pondering the question of an easy-to-use static site host. The tech industry has left us spoiled for choice here. Aside from Pages products from code hosting platforms, the major cloud infrastructure providers all have their own take on static site hosting. Companies like Netlify, Vercel, and Render offer a lot to hobbyist developers in terms of static hosting resources, with some going even further to provide Serverless-style "Functions-as-a-Service" products. 

Some of these options were ruled out by requiring source code to be hosted on Github and friends, while others were much more heavyweight than what my requirements demanded. I was also motivated by an urge to consolidate: I already had projects running on Fly.io, as well as some important configuration and infrastructure on DigitalOcean, which made me hesitant to bring another third party into the mix.

As you may have guessed from the title, my ultimate decision was to take inspiration from [a Fly.io tutorial document](https://fly.io/docs/getting-started/static/) explaining how to deploy a very simple vanilla HTML site on Fly using a Go-powered webserver. I'm going to expand on their design a bit by introducing two major components: [Nix](https://nixos.org), to give us the power to build our site with whatever static site generator (or other build process) we want to use; and [Caddy](https://caddyserver.com), to give us a more flexible and extensible platform for actually serving the content.

For the purposes of this article, we'll assume you already have your static site ready to go. Whether you're writing pure HTML by hand, or using a cutting-edge Javascript framework that renders down to static resources, you'll be able to package it up with Nix and serve it with Caddy using Fly.io.

## Before You Deploy: Nix
Much like static site hosts, static site **generators** are everywhere, and it seems like one of those things where people have particularly strong opinions on what workflow fits them best. Some people eschew a "generator" entirely and chain more purpose-built tools together to achieve the perfect bespoke output. Whatever your personal choice on generating the content for your static site, it helps to have a sort of "universal interface" to actually kick off the build process. Github and Gitlab have their own custom Continuous Integration/Continuous Delivery systems where the build for the site can be configured. Makefiles can declare a set of commands to run in a generic way, but they don't help us pull in dependencies from the outside. Dockerfiles are not only generic, but also provide some primitives to make it easy to fetch any buildtime dependencies we need. Nix, a declarative package manager, is another option that we can use to specify our build AND dependencies, without requiring us to actually make a container. Nix also provides stronger guarantees around reproducibility and hermeticity than Docker. I already use Nix flakes for virtually all of my personal work, so that's how we'll specify our build step.

Nix is a very powerful tool, but it can be intimidating to use, and I've encountered many people saying that the documentation is too sparse to be useful. I'll keep the Nix details minimal, and try to include enough explanation for what we're doing that even unfamiliar readers can follow along, but I would encourage anyone who wants some more background on Nix and Nix flakes to check out [these](https://xeiaso.net/blog/nix-flakes-1-2022-02-21) [posts](https://xeiaso.net/blog/nix-flakes-2-2022-02-27) from Xe Iaso's blog.

If you don't already have Nix installed, we'll start with that:
```bash
# macOS
sh <(curl -L https://nixos.org/nix/install)

# Linux multi-user install (recommended by Nix)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Linux single-user install (required when using SELinux)
# also Windows via WSL2
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# Docker
docker run -it nixos/nix
```

Next up, we'll enable Nix flakes as a feature, since they are still disabled by default. You can do this the easy way, by editing one of `~/.config/nix/nix.conf` or `/etc/nix/nix.conf` (if you're using a multi-user install, you'll also need to restart `nix-daemon`):
```conf
experimental-features = nix-command flakes
```

If you enjoy pain, you can do this the hard way by remembering to type this at the beginning of all your Nix commands, or setting an alias:
```bash
# one off
nix --experimental-features 'nix-command flakes' build
# sort of consistent but also not really
alias nix=nix --experimental-features 'nix-command flakes'
```

Now we can mosey on over to our site source. You might already be managing the source with Git, but if not, let's do that now:
```bash
cd site
git init
# Be careful not to commit anything secret! Git will keep a record of it
git add important/stuff but/no/secrets
git commit -m "TODO: pithy quip about starting a new endeavor"
```

Nix flakes require you to be using some form of source control that Nix understands, which means (to my understanding) either Git or Mercurial. Everything tracked by source control will end up going into the Nix store, so be doubly sure that you haven't committed any secrets, tokens, or manifestos that you don't want leaking out.

We finally have all the foundations in place to put our site's source into a flake. We can get a fresh flake by using the default template:
```bash
nix flake init
```

This will leave us with the following:
```nix
{
  description = "A very basic flake";
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
  };
}
```

Hmm. Well that's a VERY basic flake. It's also seemingly out of date, as the latest advice I've seen recommends `packages.${system}.default` over `defaultPackage.${system}`. Let's scrap that and pull in a template from the [`flake-utils`](https://github.com/numtide/flake-utils), a very popular recommendation for taming boilerplate and glue code while authoring flakes.
```bash
rm flake.nix
nix flake init --template github:numtide/flake-utils#simple-flake
```

This template will create *three* files: `flake.nix`, `shell.nix`, and `overlay.nix`. Technically, we could squish this all into a single `flake.nix` file, but breaking it down like this will help to separate our concerns and keep things focused.

### `shell.nix`: Reproducible Development Environment


### `overlay.nix`: Reproducible Site Build

### `flake.nix`: External Interface

## Serving: Caddy

## Deploying: Fly.io

## Bonus Round: Configure Everything in Nix
