{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs

    go
    go-tools
    gotools
    godef
    gopls

    vimpager-latest
  ];
  programs.neovim = {
    # TODO: keep git-blame disabled on start
    enable = true;
    extraConfig = ''
      set rnu nu
      set directory=~/.cache/nvim
      set tabstop=2
      set shiftwidth=2
      set expandtab
      highlight Normal ctermbg=NONE guibg=NONE
      colorscheme evening
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-go
      csv-vim
      coc-nvim
      coc-clangd
      coc-svelte
      coc-pyright
      vim-clang-format
      git-blame-nvim
      copilot-vim
      dart-vim-plugin
    ];
  };
}
