{ pkgs, ... }: {
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
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-go
      csv-vim
      coc-nvim
      coc-clangd
      coc-svelte
      vim-clang-format
      git-blame-nvim
    ];
  };
}
