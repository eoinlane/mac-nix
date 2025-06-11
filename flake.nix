# ~/.config/nix/flake.nix
# https://davi.sh/blog/2024/01/nix-darwin/
{
  description = "Eoin's nix darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixvim.url = "github:eoinlane/nixvim";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util, nix-vscode-extensions, nixvim, ... }:
    let
      configuration = { pkgs, ... }: {
        nix.enable = false;
        nixpkgs.config.allowUnfree = true;
        nixpkgs.config.allowBroken = true;
        nix.settings.experimental-features = "nix-command flakes";

        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 4;
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];

        users.users.eoin = {
          name = "eoin";
          home = "/Users/eoin";
        };

        security.pam.enableSudoTouchIdAuth = true;
        programs.zsh.enable = true;
        environment.systemPackages = [ pkgs.neofetch pkgs.neovim pkgs.nnn pkgs.kitty pkgs.tailscale ];
      };

      homeconfig = { pkgs, ... }: {
        home.stateVersion = "23.05";
        programs.home-manager.enable = true;

        home.packages = with pkgs; [
          nixpkgs-fmt
          coreutils-full
          inputs.nixvim.packages.${pkgs.system}.default
        ];

        home.sessionVariables = {
          EDITOR = "vim";
        };
        home.file.".vimrc".source = ./vim_configuration;

        programs.zsh = {
          enable = true;
          "oh-my-zsh" = {
            enable = true;
            theme = "agnoster";
            plugins = [ "git" "z" ];
          };
          shellAliases = {
            switch = "darwin-rebuild switch --flake ~/.config/nix#Eoins-M3-Air";
            ll = "ls -lah --color";
          };
        };

        programs.git = {
          enable = true;
          userName = "Eoin Lane";
          userEmail = "eoinlane@gmail.com";
          ignores = [ ".DS_Store" ];
          extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
        };

        programs.vscode = {
          enable = true;
          userSettings = {
            "editor.formatOnSave" = true;
            "workbench.colorTheme" = "Dracula Theme";
          };
          keybindings = [{
            key = "shift+cmd+j";
            command = "workbench.action.focusActiveEditorGroup";
            when = "terminalFocus";
          }];
          extensions = with pkgs.vscode-marketplace; [
            dracula-theme.theme-dracula
            jnoortheen.nix-ide
            vscodevim.vim
          ];
        };

        programs.kitty = {
          enable = true;
          settings = {
            shell = "${pkgs.zsh}/bin/zsh";
            shell_args = "--login";
            background_opacity = 0.8;
            confirm_os_window_close = 0;
            font_size = 14.0;
            font_family = "JetBrainsMono Nerd Font";
          };
        };
      };
    in
    {
      darwinConfigurations.Eoins-M3-Air = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.eoin = homeconfig;
          }
        ];
      };
    };
}
