{-# LANGUAGE PostfixOperators #-}

import           System.Environment        (getEnv)
import           System.IO.Unsafe          (unsafeDupablePerformIO)
import           Theme.Theme               (base00, base01, base02, base03,
                                            base04, base05, base06, base07,
                                            basebg, basefg, myFont)
import           XMonad.Hooks.StatusBar.PP (wrap, xmobarAction, xmobarColor,
                                            xmobarFont)
import           Xmobar

-- | Configures how things should be displayed on the bar
config :: Config
config =
  defaultConfig
    { font =
        concatMap
          fontWrap
          [ myFont
          , "Noto Sans:size=10:style=Bold"
          , "Noto Sans Bengali:size=10:style=Bold"
          , "Noto Sans Arabic:size=10:style=Bold"
          , "Noto Color Emoji:size=10:style=Regular"
          , "Noto Sans CJK JP:size=10:style=Bold"
          , "Noto Sans CJK KR:size=10:style=Bold"
          ]
    , additionalFonts =
        [ "xft:Font Awesome 5 Free Solid:size=10"
        , "xft:JetBrainsMono Nerd Font:size=14"
        , "xft:Font Awesome 5 Brands:size=11"
        , "xft:file\\-icons:size=11"
        , "xft:JetBrainsMono Nerd Font:size=11"
        ]
    , textOffset = 20
    , textOffsets = [20, 21, 20, 21, 20]
    , bgColor = basebg
    , fgColor = basefg
    , borderColor = base00
    , border = FullB
    , position = Static{xpos = 0, ypos = 0, width = 1920, height = 30}
    , alpha = 255
    , lowerOnStart = True
    , hideOnStart = False
    , persistent = True
    , overrideRedirect = False
    , iconRoot = homeDir <> "/.config/xmonad/icons"
    , iconOffset = -1
    , commands = myCommands
    , sepChar = "%"
    , alignSep = "}{"
    , template =
        wrap " " " " "%hasIcon%"
          <> inWrapper "%UnsafeXMonadLog%"
          <> wrap "}" "{" (inWrapper' (white "%playerctl%"))
          <> concatMap
            inWrapper
            [ red "%wttr%"
            , cpuAction "%cpu%"
            , memoryAction "%memory%"
            , volAction (white "%volwire%")
            , dateAction "%date%"
            , "%tray%"
            ]
    }
 where
  fontWrap :: String -> String
  fontWrap = wrap "" ","

  inWrapper :: String -> String
  inWrapper =
    wrap
      (xmobarColor base00 "" (xmobarFont 5 "\xe0b6"))
      (xmobarColor base00 "" (xmobarFont 5 "\xe0b4") <> " ")

  inWrapper' :: String -> String
  inWrapper' =
    wrap
      (xmobarColor base00 "" (xmobarFont 5 "\xe0b6"))
      (xmobarColor base00 "" (xmobarFont 5 "\xe0b4"))

  cpuAction, memoryAction, dateAction, volAction :: ShowS
  cpuAction x = xmobarAction "pgrep -x htop || st -e htop -s PERCENT_CPU" "1" x
  memoryAction x = xmobarAction "pgrep -x htop || st -e htop -s PERCENT_MEM" "1" x
  dateAction x = xmobarAction "~/.config/xmonad/scripts/date.sh" "1" x
  volAction x =
    xmobarAction "pamixer -t" "1" $
      xmobarAction "st -e pulsemixer" "3" $
        xmobarAction "[ $(pamixer --get-volume) -lt 200 ] && pamixer --allow-boost -u -i 5" "4" $
          xmobarAction "pamixer --allow-boost -u -d 5" "5" x

-- Custom module
data HasIcon = HasIcon deriving (Read, Show)

instance Exec HasIcon where
  alias _ = "hasIcon"
  run _ = return $ xmobarAction "xdotool key super+p" "1" $ darkPurple $ xmobarFont 2 "\xe61f"

-- | Commands to run xmobar modules on start
myCommands :: [Runnable]
myCommands =
  [ Run UnsafeXMonadLog
  , Run HasIcon
  , Run $ Cpu
    [ "-t"
    , cyan (xmobarFont 1 "\xf108" <> " <total>%")
    , "-L"
    , "50"
    , "-H"
    , "85"
    , "--low"
    , base02 <> "," <> background
    , "--normal"
    , base03 <> "," <> background
    , "--high"
    , base01 <> "," <> background
    ]
    (2 `seconds`)
  , Run $ Memory
    [ "-t"
    , purple (xmobarFont 1 "\xf538" <> " <usedratio>%")
    , "-L"
    , "50"
    , "-H"
    , "85"
    , "--low"
    , base02 <> "," <> background
    , "--normal"
    , base03 <> "," <> background
    , "--high"
    , base01 <> "," <> background
    ]
    (3 `seconds`)
  , Run $ Date (blue $ xmobarFont 1 "\xf017" <> " %l:%M %p") "date" (30 `seconds`)
  , Run $ CommandReader ("exec " <> homeDir <> "/.config/xmonad/scripts/volume.sh") "volwire"
  , Run $ CommandReader ("exec " <> homeDir <> "/.config/xmonad/scripts/playerctl.sh") "playerctl"
  , Run $ CommandReader ("exec " <> homeDir <> "/.config/xmonad/scripts/weather.sh bar") "wttr"
  , Run $ Com (homeDir <> "/.config/xmonad/scripts/tray-padding-icon.sh") ["stalonetray"] "tray" 5
  ]
  where
    -- Convenience functions
    seconds :: Int -> Int
    seconds = (* 10)
    -- minutes = (60 *). seconds

-- | Get home directory
homeDir :: String
homeDir = unsafeDupablePerformIO (getEnv "HOME")

-- Colors
background :: String
background = base00 <> ":5"

red, blue, cyan, purple, white, darkPurple :: String -> String
red = xmobarColor base01 background
blue = xmobarColor base04 background
-- green = xmobarColor base02 background
cyan = xmobarColor base06 background
-- yellow = xmobarColor base03 background
purple = xmobarColor base05 background
-- gray = xmobarColor "#7a869f" background
white = xmobarColor base07 background
darkPurple = xmobarColor "#7b6f9c" ""

main :: IO ()
main = xmobar config
