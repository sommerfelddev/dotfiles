# Agent Notes

- Keep comments in config files operational. Prefer section labels and short
  purpose notes; avoid migration history or explanations that only justify an
  old decision.
- Package placement: pacman owns system-coupled pieces; Home-Manager owns
  user-leaf tools; project compilers/linkers belong in per-project Nix dev
  shells via direnv.
- Do not add global Home-Manager packages that shadow the system build
  toolchain (`gcc`, `clang`, `ld`, `make`, `pkg-config`, language runtimes,
  etc.) unless the user explicitly asks for that tradeoff.
- On the Arch host, keep GPU/OpenGL Wayland apps in pacman unless they have
  been smoke-tested from Nix against the host graphics stack.
