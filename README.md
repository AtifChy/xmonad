# XMonad

my [xmonad](https://github.com/xmonad/xmonad) configuration

## Table of Contents

- [Preview](#preview)
- [About Setup](#about-setup)
- [Installation](#installation)
- [Keybind](#keybind)
- [License](#license)

### Preview

![preview 3](./preview/img_3.png)
![preview 1](./preview/img_1.png)
![preview 2](./preview/img_2.png)

### About Setup

- OS: [Arch Linux](https://archlinux.org/)
- WM: [XMonad](https://github.com/xmonad/xmonad)
- Bar: [Xmobar](https://github.com/jaor/xmobar)
- Prompt: [XMonad Prompt](https://github.com/xmonad/xmonad-contrib)
- Font:
  - Monospace: [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)
  - Icon Fonts:
    - [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/JetBrainsMono/Ligatures)
    - [Font Awesome 5](https://fontawesome.com/download)
    - [file-icons](https://github.com/file-icons/atom)
- Colorscheme: [onedark (slightly changed)](https://github.com/AtifChy/dotfiles/blob/main/.config/x11/colorschemes/onedark)
- Terminal: [st](https://github.com/AtifChy/st)
- Shell: [zsh](https://github.com/AtifChy/dotfiles/tree/main/.config/zsh)
  - Plugin Manager: [zinit](https://github.com/zdharma/zinit)
  - Prompt: [starship](https://github.com/AtifChy/dotfiles/blob/main/.config/starship.toml)
- Clipboard Manager: [greenclip](https://github.com/erebe/greenclip)
- Editor: [Neovim](https://github.com/AtifChy/dotfiles/tree/main/.config/nvim)
- Compositor: [Picom](https://github.com/AtifChy/dotfiles/blob/main/.config/picom/picom.conf)
- Image Preview: [Sxiv](https://github.com/muennich/sxiv)
- Wallpaper:
  <details><summary>Click Me</summary>

  ![wallpaper](./preview/the-neon-shallows-redish.png)

  </details>

- Wallpaper Setter: [hsetroot](https://github.com/himdel/hsetroot)
- Screenshot: [shotgun](https://github.com/neXromancers/shotgun)
  - Selector: [slop](https://github.com/naelstrof/slop)
  - Script: [Here](https://github.com/AtifChy/xmonad/blob/main/scripts/shotclip)
- Night Light: [gammastep](https://gitlab.com/chinstrap/gammastep)
- Music Player: [ncmpcpp](https://github.com/AtifChy/dotfiles/tree/main/.config/ncmpcpp) + [mpd](https://github.com/AtifChy/dotfiles/blob/main/.config/mpd/mpd.conf) + mpc
  - Controller: [Playerctl](https://github.com/altdesktop/playerctl) + [mpDris2](https://github.com/eonpatapon/mpDris2)
- Video Player: [mpv](https://github.com/AtifChy/dotfiles/blob/main/.config/mpv/mpv.conf)
- Notification Daemon: [Dunst](https://github.com/AtifChy/dotfiles/blob/main/.config/dunst/dunstrc)
- Tray: [Stalonetray](https://github.com/kolbusa/stalonetray)
- Lockscreen: [i3lock-color](https://github.com/Raymo111/i3lock-color) + xss-lock
- [DOTFILES](https://github.com/AtifChy/dotfiles)

### Installation

- First you need `stack` install it using your package manager or follow their [installation guide](https://docs.haskellstack.org/en/stable/install_and_upgrade/) to install it.

- Now clone the repo to `~/.config/xmonad`

```
git clone https://github.com/AtifChy/xmonad.git ~/.config/xmonad
```

- After cloning it go to that dir `cd ~/.config/xmonad` and run

```
stack install
```

> Note: This command creates a `xmonad` executable file and moves it to `~/.local/bin`. Make sure `~/.local/bin` is added to your `$PATH`.

- Recompile xmonad

```
xmonad --recompile
```

- Now you can start using xmonad. Start it using your `xinitrc`. By putting

```
exec xmonad
```

in your `xinitrc`. By default xmonad recompiles on every login. If you don't want xmonad to recompile every time you start it then put

```
exec ~/.local/share/xmonad/xmonad-x86_64-linux
```

in your `xinitrc`. It will use previously compiled binary to start xmonad.

> Note: My xmonad config reads color & font from `Xresources`. [Here you can find my Xresources](https://github.com/AtifChy/dotfiles/blob/main/.config/x11/Xresources). Merge it using `xrdb -merge /path/to/Xresources`.

### Keybind

Some basic keybinds

| Keybind                  | Function                                  |
| ------------------------ | ----------------------------------------- |
| `Super + Shift + Enter`  | Launch terminal (st)                      |
| `Super + Shift + C`      | Close window                              |
| `Super + [1..9]`         | Switch workspaces                         |
| `Super + Shift + [1..9]` | Move focused window to certain workspace  |
| `Super + P`              | Open XMonad Prompt                        |
| `Super + B`              | Toggle borders                            |
| `Super + G`              | Toggle gaps (toggle to get screen space)  |
| `Super + I`              | Increase gaps                             |
| `Super + D`              | Decrease gaps                             |
| `Super + J`              | Navigate through windows                  |
| `Super + K`              | Navigate through windows                  |
| `Super + Shift + B`      | Ignore the bar                            |
| `Super + Space`          | Switch through layouts                    |
| `Super + Shift + Space`  | Reset to default layout                   |
| `Super + T`              | Make a floating window tiled              |
| `Super + Shift + T`      | Tile all floating window                  |
| `Super + Shift + \`      | Show all keybinds (Requires. `gxmessage`) |
| `Super + Q`              | Reload xmonad                             |
| `Super + Shift + Q`      | Exit xmonad                               |

[All Keybinds](https://github.com/AtifChy/xmonad/blob/main/src/xmonad.hs#L783)

### License

[MIT](https://github.com/AtifChy/xmonad/blob/main/LICENSE)
