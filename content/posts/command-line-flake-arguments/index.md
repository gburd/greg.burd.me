---
title: "passing command line arguments to nix flakes"
date: "2022-10-10"
description: "a tutorial on 'breaking' the hermeticity of nix flakes by adding convenient command line flags"
taxonomies:
  tags: ["nix"]
extra:
  hero: true
  heroPrompt: "A rogue program hacking through the firewall, in the style of Tron Legacy, cyberpunk vibe, digital render, 8k uhd, unreal engine"
---

[Nix flakes](https://serokell.io/blog/practical-nix-flakes) are very useful, but the feature of a [fully hermetic build](https://bazel.build/basics/hermeticity) also means that they carry with them a certain degree of inflexibility. [Users have asked for a mechanism to parameterize flakes](https://github.com/NixOS/nix/issues/2861#issuecomment-891521971), but there seems to be no interest from the Nix maintainers in adding such a feature.

> While many readers will be very familiar with the concept of a function and the idea of parameterizing some piece of code or data, others might appreciate a bit of background. [Take a look at the appendix for a tangential explainer of some fundamental ideas referenced throughout this post.](#appendix)

<div id=jumpback></div>

From outside of a flake's Nix expression, the flake is a black box, a mapping from its input sources to the artifacts that it outputs. There is no built-in way to pass an arbitrary value, a boolean flag or string, from the command line in order to override a deeply nested configuration embedded in your flake. In most cases, this is fine, and you can work around many apparent needs for a one off override by building separate outputs for different purposes. Your flakes will probably come out better designed if you can use them strictly as intended.

A real-life use case where a command line override would come in handy comes from my own [nix-darwin](https://daiderd.com/nix-darwin/) configuration, where I have my [homebrew](https://brew.sh/) formulas and casks specified. I like to let Nix manage installing and upgrading these packages, but unfortunately the process to check for updates eats up a bit of time. When I'm testing a new change to some other part of my nix-darwin setup, I don't like to waste time repeatedly checking for homebrew updates. I could manually disable homebrew updates, but then I'd have to remember to flip it back on. Wouldn't it be nice to have two commands? Something like:
```bash
# rebuild the full system flake, when we want to perform homebrew updates
darwin-rebuild switch --flake <flake-path>
# rebuild without homebrew, for testing changes more quickly
darwin-rebuild switch --flake <flake-path> --no-homebrew
```

## (Ab)using Nix flake inputs to pass overrides
As mentioned, flakes are roughly equivalent to pure functions from their (aptly named) inputs to their outputs. Typically, our inputs are Nix expressions or source code that we want to use in our flake, but they can be used to smuggle in any old source code tree we want. What if we parameterized our flake with a special source input that we just use to control some behavior of the build?

While Nix has no generalized mechanism for command line overrides to flakes, there is a mechanism for *overriding flake inputs*: combine that with an input that we use for the special purpose of gating a feature or setting a value, and we have what we want.

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

[Take a look](https://git.mat.services/mat/dotfiles.nix/src/branch/main/flake.nix#L16-L17) [at how I use this](https://git.mat.services/mat/dotfiles.nix/src/branch/main/flake.nix#L256) [in my own system flake](https://git.mat.services/mat/dotfiles.nix/src/branch/main/darwin/homebrew.nix#L31).

## Appendix
[Go back to the article](#jumpback)

### Functions
In mathematics, a function is a mapping from some domain to a range. This can be expressed another way by saying that a function is a relationship between the elements of two sets, the inputs (or the domain) and the outputs (or the range). Take this simple function for example:
```
f(x) = x * 2
```

The mapping can be expressed explicitly to reveal the two sets:

| Input / Domain / `x`   | Output / Range / `f(x)`   |
| -------------------- | ----------------------- |
| ...                  | ...                     |
| -1                   | -2                      |
| 0                    | 0                       |
| 1                    | 2                       |
| ...                  | ...                     |

Functions in programs bear some similarities to mathematical functions, and many mathematical functions can be expressed simply and directly in most programming languages:
```python
def f(x):
    return x * 2
```

Most programming languages, however, do not enforce many (or any) of the laws governing mathematical functions. Functions which depend on global variables, mutable state, and side effects like user input are referred to as *impure functions*:
```python
history = []

def impure():
    # global variables
    global x
    # user input
    y = input("give me y!")
    # mutable state
    history.append((x, y))
    # user output, also a side effect
    print(x + y)
```

### Builds as Functions
In many ways, the process of building software can be compared to a function. In the simplest case, the method of building a particular piece of software could be viewed as a function:
```python
def build(source)
    software = compile(source)
    return software
```

For many build systems, the source inputs are taken from the local working directory, and additional parameters can be passed from the command line or environment. For example, `make` allows you to override variables in the `Makefile` by passing them along with the rule name:
```bash
make clone BRANCH=dev
```

`docker` allows argument and environment variable overrides to be passed to `Dockerfile` builds, container runs, and `docker-compose` stacks:
```bash
docker[-compose] build --build-arg HTTP_PROXY=http://123.123.123.123:123
docker[-compose] run   --env       DOMAIN_NAME=foo.bar
```

### Nix flakes as Pure Functions
If software builds are functions, then Nix flakes are pure functions. Indeed, the structure of a Nix flake is this:
```nix
{
  description = "Because functions are confusing without names and explanations";
  inputs = {
    builder.url = "...";
    source.url = "...";
  };
  ouputs = { self, builder, source }: {
    software = builder.build source;
  };
}
```

Which is not too far off from this:
```python
def flake(builder, source):
    return builder.build(source)
```

Nix flakes are truly pure, and Nix code running in the context of a flake is unable to access things like `builtins.currentTime`, which would be a side effect.

### Parameters and Arguments
*Parameters* and **arguments** are closely related—indeed, they are often confused or conflated entirely. I like to distinguish between them in terms of *abstract* inputs and **concrete** inputs.

Consider our same function from above: `x` stands in for any given value that our function might receive, without representing a specific value. `x` is *abstract*, and also the *parameter* of our function.

On the other hand, specific values of our domain, like -1, 0, and 1 (and actually many other numbers) are **concrete** values that can be supplied to the function to receive a specific output. Any specific value that is passed to our function is an **argument**.

### Parameterizing a Build
Now let's tie it all together.
- Builds are a bit like functions: `build(source) -> software`
- Most builds are impure, and let you do whatever you want: access the filesystem and network, check the time of day, flip a coin: `build(source, anythingElse) -> software`
- Nix flakes are pure, meaning we can't depend on things besides our explicitly specified inputs.

For an "impure" regular build, parameterizing is easy. Define a new variable or argument and pass it at the command line:
```
make install PREFIX=$HOME
docker build --build-arg VERSION v1.2
```

With Nix flakes, we have to parameterize our build with an additional source input. This is definitely a bit of a hack, but it can be very useful when you need it!

[Go back to the article](#jumpback)

## Acknowledgements
- Thank you to [Rahul Butani](https://github.com/rrbutani), the creator of the `boolean-option` Github account!
- Thank you to Hollis Druhet, my official copy editor, who has been unofficially helping out with blog edits up until now.
