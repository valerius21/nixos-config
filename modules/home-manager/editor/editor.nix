# editor.nix

{ pkgs, lib, config, ... }: {
  # declare new nixos options
  options = {
    editor.enable =
      lib.mkEnableOption "enables editor module";
  };

  # declare above options or any other nixos options
  config = lib.mkIf config.editor.enable {
     home.packages = [
       pkgs.neovim
     ];
  };
}
