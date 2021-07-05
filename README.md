# XMonad

my [xmonad](https://github.com/xmonad/xmonad) configuration

### Preview

![xmonad 1](./preview/img_1.png)
![xmonad 2](./preview/img_2.png)

### About Setup

- OS: [Arch Linux](https://archlinux.org/)
- WM: [XMonad](https://github.com/xmonad/xmonad)
- Bar: [Xmobar](https://github.com/jaor/xmobar)
- Font:
  - Monospace: [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)
- Colorscheme: onedark (slightly changed)
- Terminal: [st](https://github.com/AtifChy/st)
- Shell: [zsh](https://github.com/AtifChy/dotfiles/tree/main/.config/zsh)
  - Plugin Manager: [zinit](https://github.com/zdharma/zinit)
  - Prompt: [starship](https://github.com/AtifChy/dotfiles/blob/main/.config/starship.toml)
- Editor: [neovim](https://github.com/AtifChy/dotfiles/tree/main/.config/nvim)
- Image Preview: [sxiv](https://github.com/muennich/sxiv)
- Wallpaper:
  <details><summary>Click Me</summary>

  ![](./preview/the-neon-shallows-redish.png)

  </details>

- Wallpaper Setter: [hsetroot](https://github.com/himdel/hsetroot)
- Night Light: [redshift](https://github.com/jonls/redshift)
- Music Player: [ncmpcpp](https://github.com/AtifChy/dotfiles/tree/main/.config/ncmpcpp)

- [DOTFILES](https://github.com/AtifChy/dotfiles)

### Installation

- First you need `stack` install it using your package manager or follow their [installation guide](https://docs.haskellstack.org/en/stable/install_and_upgrade/) to install it.

- Now clone the repo to `~/.config/xmonad`

```
git clone https://github.com/AtifChy/xmonad.git ~/.config/xmonad
```

- After cloning it go to that dir `cd ~/.config/xmonad` and run

```
stack init && stack install
```

> Note: This command creates a `xmonad` executable file and moves it to `~/.local/bin`. Make sure `~/.local/bin` is added to your `$PATH`.

- Recompile xmonad

```
xmonad --recompile
```

- Now you can start using xmonad. Start it using your `xinitrc`.

### License

[MIT](https://github.com/AtifChy/xmonad/blob/main/LICENSE)
