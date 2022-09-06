+++
title = "hosting a static site on fly.io with nix and caddy"
date = "2022-09-04"
updated = "2022-09-06"
[taxonomies]
tags = ["static-site", "nix", "caddy", "fly.io"]
+++

## Motivation
So, [you've ditched Github and friends](https://sfconservancy.org/GiveUpGitHub/), [set up your own Gitea instance](@/posts/gitea-on-fly-io/index.md), and there's just one (read: at least one) thing left for you to take care of—that snazzy static site you had up on Github Pages.

### Pages and Static Site Hosting
Github Pages, and the identically named product from Gitlab, have been a part of my personal site workflow for about as long as I have been maintaining a personal site. I can remember how empowering it felt when I finally realized how much utility Github had packed into the Pages product. I went through a gleeful week of churning out Vue.js templates, starry-eyed with how easy Pages made the deployment process.

Fast forward to today, and my migration away from Github and Gitlab has me once again pondering the question of an easy-to-use static site host. The tech industry has left me spoiled for choice here. Aside from Pages products from Github and Gitlab, the major cloud infrastructure providers all have their own take on static site hosting. More specialized companies like Netlify, Vercel, and Render offer a lot to hobbyist developers in terms of static hosting resources, with some going even further to provide Serverless-style "Functions-as-a-Service" products. 

Some of these options were ruled out for me by requiring source code to be hosted on Github and friends, while others were much more heavyweight than what my requirements demanded. I was also motivated by an urge to consolidate: I already had projects running on Fly.io, as well as some important configuration and infrastructure on DigitalOcean, which made me hesitant to bring another third party into the mix.

As you may have guessed from the title, my ultimate decision was to take inspiration from [a Fly.io tutorial document](https://fly.io/docs/getting-started/static/) explaining how to deploy a very simple vanilla HTML site on Fly using a Go-powered webserver. I'm going to expand on their design a bit by introducing two major components: [Nix](https://nixos.org), to give us the power to build our site with whatever static site generator (or other build process) we want to use; and [Caddy](https://caddyserver.com), to give us a more flexible and extensible platform for actually serving the content.

For the purposes of this article, I'll assume you already have your static site ready to go. Whether you're writing pure HTML by hand, or using a cutting-edge Javascript framework that renders down to static resources, you'll be able to package it up with Nix and serve it with Caddy, all hosted on Fly.io.

## Before You Deploy: Nix
Much like static site hosts, static site **generators** are everywhere, and it seems like one of those things where people have particularly strong opinions on what workflow fits them best. Some people eschew a "generator" entirely and chain more purpose-built tools together to achieve the perfect bespoke website output. Whatever your personal choice is for generating the content for your static site, it helps to have a sort of "universal entry point" to actually kick off the build process. Github and Gitlab each have their own custom Continuous Integration/Continuous Delivery systems where the build for the site can be configured. [Makefiles](https://en.wikipedia.org/wiki/Make_(software)#Makefile) can declare a set of commands to run in a generic way, but they don't help us pull in dependencies from the outside. [Dockerfiles](https://docs.docker.com/engine/reference/builder/) are another generic build specification that also make it easy to fetch any buildtime dependencies we need. Nix, a declarative package manager, is another option that we can use to specify our build and dependencies, without necessarily requiring us to actually make a container (although we can if we want!). Nix also offers more guarantees in terms of reproducibility and hermeticity than Docker. I already use Nix flakes for virtually all of my personal work, so that's how we'll specify our build step today.

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

### `flake.nix`: Entry Point
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

Hmm. Well, that's a VERY basic flake. It's also seemingly out of date, as the latest advice I've seen recommends `packages.${system}.default` over `defaultPackage.${system}`. Let's scrap that and pull in a template from the [`flake-parts`](https://flake.parts) ([Github](https://github.com/hercules-ci/flake-parts)), a flake that bills itself as the _"Core of a distributed framework for writing Nix flakes"_. 
```bash
rm flake.nix
nix flake init --template github:hercules-ci/flake-parts
```

In my experience, `flake-parts` is an extremely helpful tool that provides some Nix functions that drastically reduce the amount of boilerplate you need for a working flake:
```nix
{
  description = "Description for the project";

  inputs = {
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages.default = pkgs.hello;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
```

All we're going to need is `systems` and `perSystem`, so let's clean up the template to look something like this:
```nix
{
  description = "Statically generated site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      # modify these as needed if you're using a different system
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = import ./shell.nix { inherit pkgs; };
        packages.default = pkgs.callPackage ./site.nix {};
      };
    };
}
```

This won't build right away. First we're going to have to add the two `.nix` files we used.

### `shell.nix`: Reproducible Development Environment
`shell.nix` is a common feature of many Nix builds, and typically specifies the packages that are used for developing and iterating on a project. If you haven't used Nix before, you likely have the dependencies and tools for your static site installed using your system package manager, or using a language-specific build tool. By switching to `shell.nix`, you can decouple the project development environment from your local system, akin to using a Docker container for development. If you don't want or need any special tools to build your site, you can mostly ignore this file, but here's what this might look like for a simple static site:
```nix
{ pkgs ? import <nixpkgs> }:
pkgs.mkShell {
  buildInputs = [
    # build your static site with one of these
    pkgs.hugo
    # or pkgs.zola or pkgs.jekyll

    # deploy with fly
    pkgs.flyctl
  ];
}
```

### `site.nix`: Reproducible Site Build
We'll write `site.nix` as a function from packages in `nixpkgs` to a derivation, which will let us call it more conveniently with `pkgs.callPackage`, as we did above in `flake.nix`. Here's an example of a site build with `hugo`:
```nix
{ stdenv, hugo, scour }:
stdenv.mkDerivation {
  name = "static-site";
  src = ./.;
  nativeBuildInputs = [
    # specify site build dependencies here
    hugo
    # optimize SVGs
    scour
  ];
  buildPhase = ''
    # prepare and build the site
    scour -i favicon-original.svg -o favicon.svg
    hugo -D
  '';
  installPhase = ''
    # install the Hugo output
    cp -r public $out
  '';
}
```

If we need to build any other auxiliary outputs, like Docker images (hint!), we can add them here. For now, let's just save our progress:
```bash
git add flake.nix shell.nix site.nix
nix flake lock
git add flake.lock
git commit -m "Initialize Nix flake"
```

Now we can test that our flake works with `nix build`:
```bash
nix build
ls result
index.html main.css ...
```

## Serving: Caddy
We can reliably build our site, but now we need a way to serve it on the [blagoblag](https://xkcd.com/181/). Let's use Caddy! The syntax is marginally less arcane than Apache or Nginx, and it has cool features like HTTPS-by-default!

Sadly, the first thing we're going to have to do in our `Caddyfile` is turn that off:
```Caddyfile
# fly.io handles https for us
{
  auto_https off
}

:8080 {
  root * {$SITE_ROOT}
  encode gzip
  file_server

  # redirect to your custom 404 page
  handle_errors {
    @404 {
      expression {http.error.status_code} == 404
    }
    rewrite @404 /404.html
    file_server
  }
}
```

You can test this by adding `caddy` to your `shell.nix` file or else installing it locally, and running something like this:
```bash
nix build
env SITE_ROOT=result caddy validate
2022/08/27 19:40:48.724 WARN    http    automatic HTTPS is completely disabled for server       {"server_name": "srv0"}
Valid configuration
env SITE_ROOT=result caddy run
```

You should be able to browse to your site at `127.0.0.1:8080` and load it, although some resources may load improperly or not at all if they are expected to be accessed at a particular hostname. When we deploy to Fly, however, everything should be working. Add the Caddyfile to git:
```bash
git add Caddyfile
git commit -m "Add Caddyfile"
```

## Deploying: Fly.io
We can scaffold a new Fly app in the usual way:
```bash
flyctl launch \
  # something unique, doesn't matter if you're going to use a custom domain
  --name seals-meander-daringly
  # region where the app runs, don't supply this option if you want to interactively choose a region \
	--region ewr \
	# don't immediately deploy, we need to edit our fly.toml first \
	--no-deploy

git add fly.toml
git commit -m "Initialize Fly app"
```

We need to find some way for Fly to build a VM from our application and Caddyfile. Fly supports Dockerfiles, so let's just go ahead and start with that:
```Dockerfile
FROM nixos/nix:latest

WORKDIR /code
ADD . /code
RUN nix \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  build

FROM caddy:latest

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=0 /code/result /var/www
ENV SITE_ROOT=/var/www
RUN caddy
```

We can use a multi-stage build to run the Nix build first, then copy that into a container with the Caddyfile and run that. We're set to deploy!
```shell
flyctl deploy
```

Now we can set up a custom domain if we want:
```bash
flyctl ips list
VERSION	IP                 	TYPE  	REGION	CREATED AT           
v4     	1.2.3.4       	    public	global	2022-08-09T02:19:27Z	
v6     	aaaa:bbbb:1::a:cccc	public	global	2022-08-09T02:19:29Z	

# add DNS A and AAAA records for the above addresses
# e.g., using doctl for digitalocean
doctl compute domain records create \
  --record-type A \
  --record-name my
  --record-data 1.2.3.4 \
  static.site

doctl compute domain records create\
  --record-type AAAA \
  --record-name my
  --record-data aaaa:bbbb:1::a:cccc \
  static.site

# get a certificate
flyctl certs add my.static.site
```

A small addition to the Caddyfile will be helpful, as well:
```Caddyfile
http://seals-meander-daringly.fly.dev {
  redir https://my.static.site
}
```

Don't forget to `flyctl deploy` again!

## Bonus Round: Configure Everything in Nix
**Update 2022-09-06**: [@rtpg on lobste.rs asked some questions about this section](https://lobste.rs/s/qydlal/hosting_static_site_on_fly_io_with_nix#c_hbto6t) which lead me to uncover that it is a bit buggy. I'm working on debugging the Nix expressions, but it may end up being blocked finding a CI/CD setup that makes me happy, so beware the section below until this message goes away.

"But mat!" you're shouting in anguish, "Why do we have to write a crummy Dockerfile to build our software? You said several sections ago that Nix could be the universal entry point, and that it was better than Docker for some important sounding reasons!"

I know. What's more is, you're entirely right. We DON'T have to settle for a Dockerfile! Nix has some tooling available to build our Docker images for us, and we can plug that right into our Fly.io application.

Let's add a `container.nix` file:
```nix
{ dockerTools, caddy, site }: 
  let
    caddyfile = builtins.readFile ./Caddyfile;
  in dockerTools.buildLayeredImage {
    name = "static-site";
    tag = "2022-08-28";

    config = {
      Cmd = [ "${caddy}/bin/caddy" "run" "-config" "${caddyfile}" ];
      Env = [
        "SITE_ROOT=${site}"
      ];
    };
  }
```

Add it to source control:
```bash
git add container.nix
git commit -m "Add Docker image build"
```

And then refer to that in our `flake.nix`:
```nix
{
  # ...
  outputs = { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      # ...
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # ...
        packages.container = pkgs.callPackage ./container.nix {
          site = config.packages.default;
        };
      };
    };
}
```

You can test that the build works like so, including running it if you have a local Docker installation:
```bash
nix build .#container
# if you have a working Docker installation
docker load < result
docker run -itp 8080:8080 static-site:2022-08-28
curl http://[::]:8080
```

Some people, myself included, don't care to run Docker engine on their Macbooks, so the easiest way for us to test this would be to package up the deployment step into a script and run it on a Linux host with Docker, such as in a container on a CI/CD server.

Let's add another `callPackage` friendly Nix file:
```nix
{ lib, docker, flyctl, formats, writeShellScriptBin, dockerImage }:
writeShellScriptBin "deploy" ''
  set -euxo pipefail
  export PATH="${lib.makeBinPath [(docker.override { clientOnly = true; }) flyctl]}:$PATH"
  archive=${dockerImage}
  image=$(docker load < $archive | awk '{ print $3; }')
  flyctl deploy -i $image
''
```

And plug it into the flake:
```nix
{
  # ...
  outputs = { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      # ...
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # ...
        apps.deploy = pkgs.callPackage ./deploy.nix {
          dockerImage = config.packages.container;
        };
      };
    };
}
```

Now you should be able to use a command like this on a Docker-friendly host, and your site will be up and running before long:
```bash
nix run .#deploy
```

### Future Directions
There is just a touch of boilerplate left in `flake.nix`, required to thread the correct nixpkgs context through (`callPackage`, passing `site` and `dockerImage` explicitly). We could easily package that up in a `flake-module.nix` and add it to the `imports` argument of `flake-parts.lib.mkFlake`. I'll probably try to make another blog post out of the process of packaging up the Nix glue, so keep your eyes peeled!

Thanks for reading!

## Acknowledgements
- [Thanks to Lutris, Inc. for their `nix-fly-template`, which was very influential in the writing of this post.](https://github.com/LutrisEng/nix-fly-template)
- Thanks to Hollis Druhet for reading the draft of this post and offering feedback!
