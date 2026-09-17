{
  description = "Home-Manager profiles for the Arch host and the Ubuntu remote-dev VM.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      # Track the Home Manager branch whose release.json matches nixpkgs'
      # lib.version. nixos-unstable currently reports 26.11pre-git, while
      # home-manager's latest release branch is still 26.05, so master is the
      # matching input until release-26.11 exists.
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # tuicr: TUI git-change reviewer. Upstream flake exposes
    # `packages.<system>.default`. Pulled here instead of nixpkgs because
    # it's not packaged there. The skill files under
    # `dot_claude/skills/tuicr/` rely on the `tuicr` binary being on PATH.
    tuicr = {
      url = "github:ruifm/tuicr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aibox = {
      url = "github:ruifm/aibox";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      tuicr,
      aibox,
      ...
    }:
    let
      releases = builtins.fromJSON (builtins.readFile ./releases.json);
      hermes = builtins.getFlake "github:NousResearch/hermes-agent/${releases.hermes.rev}";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Expose external flake packages so common.nix can list them next to
          # nixpkgs packages without threading inputs into every module.
          (final: prev: {
            tuicr = tuicr.packages.${system}.default;
            aibox = aibox.packages.${system}.default;
            claude-release = prev.claude-code.overrideAttrs {
              version = releases.claude.version;
              src = final.fetchurl {
                inherit (releases.claude) url hash;
              };
            };
            copilot-release = final.stdenvNoCC.mkDerivation {
              pname = "github-copilot-cli";
              version = releases.copilot.version;
              src = final.fetchurl {
                inherit (releases.copilot) url hash;
              };
              sourceRoot = ".";
              nativeBuildInputs = [
                final.autoPatchelfHook
                final.makeBinaryWrapper
              ];
              buildInputs = [
                final.glibc
                final.stdenv.cc.cc.lib
                final.glib
                final.libsecret
              ];
              runtimeDependencies = [
                final.glibc
                final.stdenv.cc.cc.lib
                final.glib
                final.libsecret
              ];
              dontStrip = true;
              installPhase = ''
                runHook preInstall
                install -Dm755 copilot "$out/libexec/copilot"
                makeWrapper "$out/libexec/copilot" "$out/bin/copilot" \
                  --add-flag --no-auto-update \
                  --set-default SSL_CERT_DIR ${final.cacert}/etc/ssl/certs \
                  --prefix PATH : ${final.lib.makeBinPath [ final.bash ]}
                runHook postInstall
              '';
              meta = {
                description = "GitHub Copilot CLI";
                homepage = "https://github.com/github/copilot-cli";
                license = final.lib.licenses.unfree;
                mainProgram = "copilot";
                platforms = [ "x86_64-linux" ];
                sourceProvenance = with final.lib.sourceTypes; [
                  binaryNativeCode
                  binaryBytecode
                  obfuscatedCode
                ];
              };
            };
            codex-release = final.stdenvNoCC.mkDerivation {
              pname = "codex";
              version = releases.codex.version;
              src = final.fetchurl {
                inherit (releases.codex) url hash;
              };
              sourceRoot = ".";
              nativeBuildInputs = [ final.autoPatchelfHook ];
              buildInputs = [
                final.glibc
                final.ncurses
              ];
              runtimeDependencies = [
                final.glibc
                final.ncurses
              ];
              installPhase = ''
                runHook preInstall
                mkdir -p "$out"
                cp -R . "$out/"
                chmod -R u+w "$out"
                runHook postInstall
              '';
              meta = {
                description = "OpenAI Codex CLI";
                homepage = "https://developers.openai.com/codex/cli";
                license = final.lib.licenses.asl20;
                mainProgram = "codex";
                platforms = [ "x86_64-linux" ];
                sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
              };
            };
            hermes-release = hermes.packages.${system}.minimal;
            omp-release = final.stdenvNoCC.mkDerivation {
              pname = "oh-my-pi";
              version = releases.omp.version;
              src = final.fetchurl {
                inherit (releases.omp) url hash;
              };
              dontUnpack = true;
              nativeBuildInputs = [ final.makeBinaryWrapper ];
              dontStrip = true;
              installPhase = ''
                runHook preInstall
                install -Dm755 "$src" "$out/libexec/omp"
                makeWrapper ${final.glibc}/lib/ld-linux-x86-64.so.2 "$out/bin/omp" \
                  --add-flags --library-path \
                  --add-flags ${final.glibc}/lib \
                  --add-flags "$out/libexec/omp"
                runHook postInstall
              '';
              meta = {
                description = "AI coding agent for the terminal";
                homepage = "https://github.com/can1357/oh-my-pi";
                license = final.lib.licenses.mit;
                mainProgram = "omp";
                platforms = [ "x86_64-linux" ];
                sourceProvenance = with final.lib.sourceTypes; [
                  binaryNativeCode
                  binaryBytecode
                ];
              };
            };
            opencode-release = final.stdenvNoCC.mkDerivation {
              pname = "opencode";
              version = releases.opencode.version;
              src = final.fetchurl {
                inherit (releases.opencode) url hash;
              };
              sourceRoot = ".";
              nativeBuildInputs = [
                final.autoPatchelfHook
                final.makeBinaryWrapper
              ];
              buildInputs = [ final.glibc ];
              runtimeDependencies = [ final.glibc ];
              dontStrip = true;
              installPhase = ''
                runHook preInstall
                install -Dm755 opencode "$out/bin/opencode"
                wrapProgram "$out/bin/opencode" \
                  --prefix PATH : ${final.lib.makeBinPath [ final.ripgrep ]} \
                  --set OPENCODE_DISABLE_AUTOUPDATE true
                runHook postInstall
              '';
              meta = {
                description = "AI coding agent built for the terminal";
                homepage = "https://opencode.ai";
                license = final.lib.licenses.mit;
                mainProgram = "opencode";
                platforms = [ "x86_64-linux" ];
                sourceProvenance = with final.lib.sourceTypes; [
                  binaryNativeCode
                  binaryBytecode
                ];
              };
            };
            ori-release = final.stdenvNoCC.mkDerivation {
              pname = "ori";
              version = releases.ori.version;
              src = final.fetchurl {
                inherit (releases.ori) url hash;
              };
              dontUnpack = true;
              nativeBuildInputs = [ final.makeBinaryWrapper ];
              dontStrip = true;
              installPhase = ''
                runHook preInstall
                install -Dm755 "$src" "$out/libexec/ori"
                makeWrapper ${final.glibc}/lib/ld-linux-x86-64.so.2 "$out/bin/ori" \
                  --add-flags --library-path \
                  --add-flags ${final.glibc}/lib \
                  --add-flags "$out/libexec/ori" \
                  --set ORI_NO_UPDATE_CHECK 1 \
                  --set ORI_TELEMETRY 0
                runHook postInstall
              '';
              meta = {
                description = "OpenRouter harness for local coding agents";
                homepage = "https://openrouter.ai/blog/announcements/ori-harness/";
                license = final.lib.licenses.asl20;
                mainProgram = "ori";
                platforms = [ "x86_64-linux" ];
                sourceProvenance = with final.lib.sourceTypes; [
                  binaryNativeCode
                  binaryBytecode
                ];
              };
            };
          })
        ];
        # Whitelist specific unfree packages instead of globally setting allowUnfree,
        # so a typo elsewhere can't silently pull in additional unfree
        # deps.
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "github-copilot-cli"
          ];
        config.permittedInsecurePackages = [
          # Keybase requires an EOL Electron release for desktop notifications.
          "keybase-gui-6.5.1"
        ];
      };

      mkProfile =
        module:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ module ];
          # Path to the cloned dotfiles checkout — passed in so the
          # modules can symlink shared configs from the same repo.
          extraSpecialArgs = {
            dotfilesRoot = ../.;
          };
        };
    in
    {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          basedpyright
          chezmoi
          git
          jq
          python3
          just
          nixfmt
          prettier
          ruff
          selene
          shellcheck
          shfmt
          stylua
          taplo
        ];
      };

      homeConfigurations = {
        vm = mkProfile ./vm.nix;
        host = mkProfile ./host.nix;
        canonical = mkProfile ./canonical.nix;
      };
    };
}
