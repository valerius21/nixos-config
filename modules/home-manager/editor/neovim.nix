# neovim.nix

{ pkgs, lib, config, ... }: {
  # declare new nixos options
  options = {
    neovim.enable =
      lib.mkEnableOption "enables neovim module";
  };

  # declare above options or any other nixos options
  config = lib.mkIf config.neovim.enable {
    home.packages = [ 
      pkgs.git
      pkgs.neovim
      pkgs.unzip
      pkgs.ripgrep
    ];
    home.activation.cloneKickstart = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.config/nvim/.git" ]; then
        ${pkgs.git}/bin/git clone https://github.com/valerius21/kickstart.nvim "$HOME/.config/nvim"
      fi
    '';
  };
}
