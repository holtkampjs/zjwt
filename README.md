# ZJWT

I've been working around JSON Web Tokens (JWTs) a lot recently and learning the Zig programming language. I've also been working with Nix. Writing a JWT encoder / decoder in Zig with Nix for environment management seems like an apt project to combine some of the tools I've been dealing with and put them to use.

## Tasks

- [x] Initialize Git repo
- [x] Set up upstream repository on GitHub
- [ ] Create `flake.nix`
      This file should include environment dependencies. Namely this includes Zig on the latest stable version. The desired state is to be able to run `nix develop` and being dropped into a shell with all of the dependencies necessary for work on the project. I believe there is also a `nix build` command which could be configured to run `zig build ...`.
- [ ] Write Base64 encoder / decoder (library)
- [ ] Read JWT RFC document

## Features

- [ ] Decode JWT
- [ ] Encode JWT
