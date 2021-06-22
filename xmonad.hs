{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE LambdaCase                #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

--
-- Imports
--
import           Control.Monad                       (liftM2)
import qualified Data.Map                            as M
import           Data.Maybe                          (isJust)
import           Data.Monoid                         (All)
import           System.Exit                         (exitSuccess)
import           XMonad                              hiding ((|||))
import           XMonad.Actions.CopyWindow           (copyToAll, kill1,
                                                      killAllOtherCopies)
import           XMonad.Actions.CycleWS              (Direction1D (..), emptyWS,
                                                      ignoringWSs, moveTo,
                                                      shiftTo, toggleWS')
import qualified XMonad.Actions.FlexibleResize       as Flex
import           XMonad.Actions.Promote              (promote)
import           XMonad.Actions.TiledWindowDragging  (dragWindow)
import           XMonad.Actions.WithAll              (killAll, sinkAll)
import           XMonad.Hooks.EwmhDesktops           (activateLogHook, ewmh,
                                                      ewmhFullscreen)
import           XMonad.Hooks.ManageDocks            (ToggleStruts (..),
                                                      avoidStruts, docks)
import           XMonad.Hooks.ManageHelpers          (composeOne, doCenterFloat,
                                                      doFullFloat, isDialog,
                                                      isFullscreen, transience,
                                                      (-?>))
import           XMonad.Hooks.StatusBar              (StatusBarConfig,
                                                      statusBarProp, withSB)
import           XMonad.Hooks.StatusBar.PP           (PP (..), filterOutWsPP,
                                                      shorten, wrap,
                                                      xmobarAction,
                                                      xmobarBorder, xmobarColor,
                                                      xmobarStrip)
import           XMonad.Hooks.WindowSwallowing       (swallowEventHook)
import           XMonad.Layout.Accordion             (Accordion (Accordion))
import           XMonad.Layout.DraggingVisualizer    (draggingVisualizer)
import           XMonad.Layout.LayoutCombinators     (JumpToLayout (..), (|||))
import           XMonad.Layout.LayoutModifier        (ModifiedLayout)
import           XMonad.Layout.MultiToggle           (EOT (..), Toggle (..),
                                                      mkToggle, (??))
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (NBFULL, NOBORDERS))
import           XMonad.Layout.NoBorders             (smartBorders)
import           XMonad.Layout.Renamed               (Rename (Replace), renamed)
import           XMonad.Layout.ResizableTile         (MirrorResize (..),
                                                      ResizableTall (..))
import           XMonad.Layout.Simplest              (Simplest (Simplest))
import           XMonad.Layout.Spacing               (Border (..), Spacing,
                                                      decScreenSpacing,
                                                      decScreenWindowSpacing,
                                                      decWindowSpacing,
                                                      incScreenSpacing,
                                                      incScreenWindowSpacing,
                                                      incWindowSpacing,
                                                      spacingRaw,
                                                      toggleScreenSpacingEnabled,
                                                      toggleWindowSpacingEnabled)
import           XMonad.Layout.SubLayouts            (GroupMsg (..), onGroup,
                                                      pullGroup, subLayout,
                                                      toSubl)
import           XMonad.Layout.Tabbed                (Theme (..), addTabs,
                                                      shrinkText)
import           XMonad.Layout.ThreeColumns          (ThreeCol (ThreeColMid))
import           XMonad.Layout.WindowNavigation      (Direction2D (..),
                                                      windowNavigation)
import           XMonad.Prompt                       (XPConfig (..),
                                                      XPPosition (..),
                                                      defaultXPKeymap,
                                                      deleteAllDuplicates)
import           XMonad.Prompt.ConfirmPrompt         (confirmPrompt)
import           XMonad.Prompt.FuzzyMatch            (fuzzyMatch, fuzzySort)
import           XMonad.Prompt.Man                   (manPrompt)
import           XMonad.Prompt.Shell                 (shellPrompt)
import qualified XMonad.StackSet                     as W
import           XMonad.Util.ClickableWorkspaces     (clickablePP)
import           XMonad.Util.Cursor                  (setDefaultCursor)
import           XMonad.Util.DynamicScratchpads      (makeDynamicSP,
                                                      spawnDynamicSP)
import           XMonad.Util.Loggers                 (xmobarColorL)
import           XMonad.Util.NamedScratchpad         (NamedScratchpad (NS),
                                                      customFloating,
                                                      namedScratchpadAction,
                                                      namedScratchpadManageHook,
                                                      scratchpadWorkspaceTag)
import           XMonad.Util.Run                     (safeSpawn, unsafeSpawn)
import           XMonad.Util.SpawnOnce               (spawnOnce)
import           XMonad.Util.Ungrab                  (unGrab)


-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal :: String
myTerminal = "st"

-- My launcher
--
myLauncher :: String
myLauncher =
  "rofi -theme ~/.config/rofi/themes/slate.rasi -width 624 -lines 12"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth :: Dimension
myBorderWidth = 2

myGaps :: Num p => p
myGaps = 8

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask, altMask :: KeyMask
myModMask = mod4Mask
altMask = mod1Mask

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
myWorkspaces :: [WorkspaceId]
myWorkspaces =
  ["TERM", "WEB", "CHAT", "CODE", "MOVIE", "GAME", "VBOX", "TOR", "MISC"]

-- Get count of available windows on a workspace
--
windowCount :: X (Maybe String)
windowCount =
  gets
    $ Just
    . show
    . length
    . W.integrate'
    . W.stack
    . W.workspace
    . W.current
    . windowset

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor, myFocusedBorderColor :: String
myNormalBorderColor = "#1e2127"
myFocusedBorderColor = "#4280bd"

-- Custom font
myFont :: String
myFont = "xft:JetBrains Mono:size=10:style=Bold:antialias=true:hinting=true"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@XConfig { XMonad.modMask = modm } =
  M.fromList
    $  [
       -- launch a terminal
         ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

       -- launch dmenu
       --, ((altMask, xK_p), spawn "dmenu_run -p 'Run:' -w 1916")

       -- launch greenclip-dmenu
       --, ((altMask, xK_c), spawn "greenclip print | sed '/^$/d' | dmenu -s -l 10 -g 2 -w 1916 -p 'Clipboard:' | xargs -r -d'\n' -I '{}' greenclip print '{}'")

       -- launch rofi
       , ( (altMask, xK_p)
         , unsafeSpawn
           (  myLauncher
           ++ " -show combi -combi-modi window,drun -modi combi -show-icons"
           )
         )

       -- launch rofi-greenclip
       , ( (modm, xK_c)
         , unsafeSpawn
           (myLauncher
           ++ " -show Clipboard -modi 'Clipboard:greenclip print' -run-command '{cmd}'"
           )
         )

       -- launch gmrun
       --, ((modm .|. shiftMask, xK_p ), safeSpawn "gmrun" [])

       -- close focused window
       , ((modm .|. shiftMask, xK_c)    , kill1)

       -- close all windows on the current workspace
       , ((modm .|. controlMask, xK_c)  , killAll)

       -- Rotate through the available layout algorithms
       , ((modm, xK_space)              , sendMessage NextLayout)

       --  Reset the layouts on the current workspace to default
       , ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf)

       -- Resize viewed windows to the correct size
       , ((modm, xK_n)                  , refresh)

       -- Move focus to the next window
       , ((modm, xK_j)                  , windows W.focusDown)

       -- Move focus to the previous window
       , ((modm, xK_k)                  , windows W.focusUp)

       -- Move focus to the master window
       , ((modm, xK_m)                  , windows W.focusMaster)

       -- Swap the focused window and the master window
       -- , ((modm, xK_Return)             , windows W.swapMaster)

       -- Swap the focused window with the next window
       , ((modm .|. shiftMask, xK_j)    , windows W.swapDown)

       -- Swap the focused window with the previous window
       , ((modm .|. shiftMask, xK_k)    , windows W.swapUp)

       -- Shrink the master area
       , ((modm, xK_h)                  , sendMessage Shrink)

       -- Expand the master area
       , ((modm, xK_l)                  , sendMessage Expand)

       -- Shrink focused windows height
       , ((modm, xK_a)                  , sendMessage MirrorShrink)

       -- Expand focused windows height
       , ((modm, xK_s)                  , sendMessage MirrorExpand)

       -- Push window back into tiling
       , ((modm, xK_t)                  , withFocused $ windows . W.sink)

       -- Push all windows on the current workspace into tiling
       , ((modm .|. shiftMask, xK_t)    , sinkAll)

       -- Increment the number of windows in the master area
       , ((modm, xK_comma)              , sendMessage (IncMasterN 1))

       -- Deincrement the number of windows in the master area
       , ((modm, xK_period)             , sendMessage (IncMasterN (-1)))

       -- Toggle the status bar gap
       -- Use this binding with avoidStruts from Hooks.ManageDocks.
       -- See also the statusBar function from Hooks.DynamicLog.
       --
       , ((modm .|. shiftMask, xK_b)    , sendMessage ToggleStruts)

       -- Quit xmonad
       , ( (modm .|. shiftMask, xK_q)
         , confirmPrompt myXPConfig "Quit" $ io exitSuccess
         )

       -- Restart xmonad
       , ((modm, xK_q), unsafeSpawn "xmonad --recompile; xmonad --restart")

       -- Moves the focused window to the master pane
       , ((modm, xK_Return), promote)

       -- Run xmessage with a summary of the default keybindings (useful for beginners)
       , ( (modm .|. shiftMask, xK_slash)
         , unsafeSpawn
           ("printf \"" ++ help ++ "\" | gxmessage -fn 'JetBrains Mono' -file -")
         )
       , ((modm, xK_b)                  , sendMessage $ Toggle NOBORDERS)
       , ((modm, xK_f)                  , sendMessage $ Toggle NBFULL)

       -- CycleWS setup
       , ((modm, xK_Right)              , moveTo Next noNSP)
       , ((modm, xK_Left)               , moveTo Prev noNSP)
       , ((modm .|. shiftMask, xK_Right), shiftTo Next noNSP)
       , ((modm .|. shiftMask, xK_Left) , shiftTo Prev noNSP)
       , ((modm, xK_Tab)                , toggleWS' ["NSP"])
       , ((modm .|. shiftMask, xK_f)    , moveTo Next emptyWS)

       -- Increase/Decrease spacing (gaps)
       , ( (modm, xK_g)
         , sequence_ [toggleScreenSpacingEnabled, toggleWindowSpacingEnabled]
         )
       , ((modm, xK_i)                     , incScreenWindowSpacing 2)
       , ((modm, xK_d)                     , decScreenWindowSpacing 2)
       , ((altMask, xK_i)                  , incScreenSpacing 2)
       , ((altMask, xK_d)                  , decScreenSpacing 2)
       , ((altMask .|. shiftMask, xK_i)    , incWindowSpacing 2)
       , ((altMask .|. shiftMask, xK_d)    , decWindowSpacing 2)

       -- SubLayouts
       , ((modm .|. controlMask, xK_h)     , sendMessage $ pullGroup L)
       , ((modm .|. controlMask, xK_l)     , sendMessage $ pullGroup R)
       , ((modm .|. controlMask, xK_k)     , sendMessage $ pullGroup U)
       , ((modm .|. controlMask, xK_j)     , sendMessage $ pullGroup D)
       , ((modm .|. controlMask, xK_space) , toSubl NextLayout)
       , ((modm .|. controlMask, xK_m), withFocused (sendMessage . MergeAll))
       , ((modm .|. controlMask, xK_u), withFocused (sendMessage . UnMerge))
       , ((modm .|. controlMask, xK_comma) , onGroup W.focusUp')
       , ((modm .|. controlMask, xK_period), onGroup W.focusDown')

       -- Copy window
       , ((modm, xK_v)                     , windows copyToAll)
       , ((modm .|. shiftMask, xK_v)       , killAllOtherCopies)

       -- Scratchpad
       , ( (modm .|. controlMask, xK_Return)
         , namedScratchpadAction myScratchpads "terminal"
         )

       -- Dynamic scratchpads
       , ((modm .|. shiftMask, xK_equal), withFocused $ makeDynamicSP "dyn1")
       , ((modm .|. shiftMask, xK_minus), withFocused $ makeDynamicSP "dyn2")
       , ((modm, xK_equal)              , spawnDynamicSP "dyn1")
       , ((modm, xK_minus)              , spawnDynamicSP "dyn2")

       -- Easily switch your layouts
       , ((altMask, xK_t)               , sendMessage $ JumpToLayout "Tall")
       , ((altMask, xK_c), sendMessage $ JumpToLayout "Centered Master")

       -- XPrompt
       , ((modm, xK_p)                  , shellPrompt myXPConfig)
       , ((modm, xK_F1)                 , manPrompt myXPConfig)

       -- Open apps
       , ( (altMask, xK_F9)
         , unGrab
           >> unsafeSpawn
                "$(killall picom && notify-send -u critical -i picom 'System' 'Killed Picom') || $(picom & notify-send -u critical -i picom 'System' 'Picom running...')"
         )
       , ((altMask, xK_e), safeSpawn "emacsclient" ["-nc"])
       , ((altMask, xK_b), safeSpawn "firefox" [])

       -- lock screen
       , ( (modm .|. shiftMask, xK_l)
         , unGrab >> safeSpawn "loginctl" ["lock-session"]
         )

       -- Screenshot shortcuts (Requires: shotgun, slop, xdotool)
       , ((0, xK_Print)                , unGrab >> safeSpawn "shotclip" ["-f"])
       , ((0 .|. controlMask, xK_Print), unGrab >> safeSpawn "shotclip" ["-w"])
       , ((0 .|. shiftMask, xK_Print)  , unGrab >> safeSpawn "shotclip" ["-s"])
       ]
    ++
       --
       -- mod-[1..9], Switch to workspace N
       -- mod-shift-[1..9], Move client to workspace N
       --
       [ ((m .|. modm, k), windows $ f i)
       | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
       , (f, m) <-
         [ (W.greedyView                   , 0)
         , (W.shift                        , shiftMask)
         , (liftM2 (.) W.greedyView W.shift, controlMask)
         ]
       ]
    ++
       --
       -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
       -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
       --
       [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
       | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..]
       , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
       ]
  where noNSP = ignoringWSs [scratchpadWorkspaceTag]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings :: XConfig l -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings XConfig { XMonad.modMask = modm } = M.fromList
  -- mod-button1, Set the window to floating mode and move by dragging
  [ ( (modm, button1)
    , \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster
    )

  -- mod-button2, Raise the window to the top of the stack
  , ((modm, button2), \w -> focus w >> windows W.shiftMaster)

  -- mod-button3, Set the window to floating mode and resize by dragging
  , ( (modm, button3)
    , \w -> focus w >> Flex.mouseResizeWindow w >> windows W.shiftMaster
    )

  -- scroll the mouse wheel (button4 and button5)
  , ((modm, button4)              , \w -> focus w >> moveTo Prev noNSP)
  , ((modm, button5)              , \w -> focus w >> moveTo Next noNSP)

  -- drag windows
  , ((modm .|. shiftMask, button1), dragWindow)
  ]
  where noNSP = ignoringWSs [scratchpadWorkspaceTag]

------------------------------------------------------------------------
-- XPrompt
--
myXPConfig :: XPConfig
myXPConfig = def { font                = myFont
                 , bgColor             = "#1e2127"
                 , fgColor             = "#d8dee9"
                 , bgHLight            = "#4280bd"
                 , fgHLight            = "#000000"
                 , borderColor         = "#434c5e"
                 , promptBorderWidth   = 1
                 , promptKeymap        = defaultXPKeymap
                 , position            = Top
                 -- , position            = CenteredAt {xpCenterY = 0.3, xpWidth = 0.3}
                 , height              = 28
                 , historySize         = 50
                 , historyFilter       = deleteAllDuplicates
                 , defaultText         = []
                 -- , autoComplete        = Just 100000,   -- set Just 100000 for .1 sec
                 , showCompletionOnTab = False          -- False means auto completion
                 , alwaysHighlight     = True           -- Disables tab cycle
                 , maxComplRows        = Just 10        -- set to 'Just 5' for 5 rows
                 , searchPredicate     = fuzzyMatch
                 , sorter              = fuzzySort
                 }

------------------------------------------------------------------------
-- Spacing (gaps)
mySpacing
  :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Tab theme
myTabConfig :: Theme
myTabConfig = def { activeColor         = "#4280bd"
                  , activeBorderColor   = "#434c5e"
                  , activeTextColor     = "#d8dee9"
                  , inactiveColor       = "#1e2127"
                  , inactiveBorderColor = "#1e2127"
                  , inactiveTextColor   = "#434c5e"
                  , fontName            = myFont
                  , decoHeight          = 22
                  , decoWidth           = maxBound
                  }

-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--

myLayout =
  avoidStruts
    $ mkToggle (NBFULL ?? NOBORDERS ?? EOT)
    $ (tall ||| mtall ||| center)
 where
  -- default tiling algorithm partitions the screen into two panes
  tall =
    renamed [Replace "Tall"]
      $ smartBorders
      $ addTabs shrinkText myTabConfig
      $ subLayout [] (Simplest ||| Accordion)
      $ windowNavigation
      $ draggingVisualizer
      $ mySpacing myGaps
      $ ResizableTall nmaster delta ratio []

  mtall =
    renamed [Replace "Mirror Tall"]
      $ addTabs shrinkText myTabConfig
      $ subLayout [] (Simplest ||| Accordion)
      $ windowNavigation
      $ draggingVisualizer
      $ Mirror tall

  center =
    renamed [Replace "Centered Master"]
      $ smartBorders
      $ addTabs shrinkText myTabConfig
      $ subLayout [] (Simplest ||| Accordion)
      $ windowNavigation
      $ draggingVisualizer
      $ mySpacing myGaps
      $ ThreeColMid nmaster delta ratio

  -- The default number of windows in the master pane
  nmaster = 1

  -- Default proportion of screen occupied by master pane
  ratio   = 1 / 2

  -- Percent of screen to increment by when resizing panes
  delta   = 3 / 100

------------------------------------------------------------------------
-- Scratchpad
--
myScratchpads :: [NamedScratchpad]
myScratchpads = [
                 -- run a terminal inside scratchpad
                 NS "terminal" spawnTerm findTerm manageTerm]
 where
  spawnTerm  = myTerminal ++ " -c scratchpad"
  findTerm   = className =? "scratchpad"
  manageTerm = customFloating $ W.RationalRect (1 / 6) (1 / 8) (2 / 3) (3 / 4)

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
-- workspace number starts from 0
--

myManageHook :: ManageHook
myManageHook =
  composeOne
      [ className =? "MPlayer" -?> doFloat
      , resource =? "desktop_window" -?> doIgnore
      , resource =? "kdesktop" -?> doIgnore
      , resource =? "redshift-gtk" -?> doCenterFloat
      , className =? "ibus-ui-gtk3" -?> doIgnore
      , resource =? "gcr-prompter" -?> doCenterFloat
      , resource =? "Browser" -?> doCenterFloat
      , title =? "Picture-in-Picture" -?> doFloat
      , title =? "Open Folder" -?> doCenterFloat
      , className =? "St-float" -?> doFloat
      , transience
      , title =? "Save Image" <&&> className =? "Gimp" -?> doCenterFloat
      , isFullscreen -?> doFullFloat
      , isDialog -?> doCenterFloat
      , className =? "firefox" -?> doShift (myWorkspaces !! 1)
      , className =? "discord" -?> doShift (myWorkspaces !! 2)
      , className =? "code-oss" -?> doShift (myWorkspaces !! 3)
      , className =? "Lutris" -?> doShift (myWorkspaces !! 5)
      , className
      =?   "VirtualBox Manager"
      <||> className
      =?   "gnome-boxes"
      -?>  doShift (myWorkspaces !! 6)
      ]
    <+> namedScratchpadManageHook myScratchpads

------------------------------------------------------------------------
-- Event handling

-- * EwmhDesktops users should change this to ewmhDesktopsEventHook

--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myHandleEventHook :: Event -> X All
myHandleEventHook = handleEventHook def <+> swallowEventHook
  (    className
  =?   "Alacritty"
  <||> className
  =?   "St"
  <||> className
  =?   "org.wezfurlong.wezterm"
  <||> className
  =?   "kitty"
  )
  (    (   not
       <$> (    className
           =?   "St"
           <||> className
           =?   "Dragon"
           <||> className
           =?   "noswallow"
           )
       )
  <||> className
  =?   "re"
  )

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
--
-- myLogHook :: X ()
-- myLogHook = mempty

myXmobarPP :: PP
myXmobarPP = def
  { ppSep           = gray " │ "
  , ppTitleSanitize = xmobarStrip
  , ppCurrent       = blue . wrap "" "" . xmobarBorder "Bottom" "#8be9fd" 2
  , ppHidden        = lowWhite . wrap "" ""
  , ppWsSep         = "  "
  , ppTitle = magenta . xmobarAction "xdotool key Super+shift+c" "2" . shorten 40
  , ppOrder         = \[ws, l, t, ex] -> [ws, l, ex, t]
  , ppExtras        = [xmobarColorL "#ff6c6b" "" $ windowCount]
  , ppLayout = green . xmobarAction "xdotool key Super+space" "1" . xmobarAction
                 "xdotool key Super+shift+space"
                 "3"
  }
 where
  blue, lowWhite, magenta, red, white, yellow, purple, green
    :: String -> String
  magenta  = xmobarColor "#b48ead" ""
  blue     = xmobarColor "#51afef" ""
  purple   = xmobarColor "#bd93f9" ""
  lowBlue  = xmobarColor "#8be9fd" ""
  white    = xmobarColor "#f8f8f2" ""
  yellow   = xmobarColor "#f1fa8c" ""
  red      = xmobarColor "#ff6c6b" ""
  lowWhite = xmobarColor "#a6aebf" ""
  gray     = xmobarColor "#434c5e" ""
  green    = xmobarColor "#c3e88d" ""

mySB :: StatusBarConfig
mySB = statusBarProp
  "xmobar ~/.config/xmonad/xmobar/xmobarrc"
  (clickablePP (filterOutWsPP [scratchpadWorkspaceTag] myXmobarPP))

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
myStartupHook :: X ()
myStartupHook = do
  setDefaultCursor xC_left_ptr
  spawnOnce "xwallpaper --zoom ~/Pictures/macOS-Big-Sur-night.jpg"
  -- spawnOnce "feh --no-fehbg --bg-scale ~/Pictures/Wallpapers/0057.jpg"
  -- spawn "feh --bg-scale --randomize --no-fehbg ~/Pictures/Wallpapers/*"
  spawnOnce "picom"
  spawnOnce "dunst"
  spawnOnce "nm-applet"
  spawnOnce "redshift-gtk"
  spawnOnce "greenclip daemon"
  spawnOnce "numlockx"
  -- spawnOnce "emacs --daemon"
  spawnOnce "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  -- spawnOnce "pasystray -t --notify=systray_action"
  spawnOnce "ibus-daemon -drx"
  spawnOnce "xss-lock -- lockctl -t 30 -l"
  spawn "pulsepipe"
  spawnOnce
    "stalonetray --geometry 1x1-6+4 --max-geometry 10x1-6+4 --transparent --tint-color '#1E2127' --tint-level 255 --grow-gravity NE --icon-gravity NW --icon-size 20 --sticky --window-type dock --window-strut top --skip-taskbar"
  -- spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 --tint 0x1e2127  --height 22 --iconspacing 5 --distance 2,2 --distancefrom top,right"
  -- spawn "systemctl --user restart redshift-gtk.service"

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main :: IO ()
main = do
  let acMh :: ManageHook
      acMh = reader W.focusWindow >>= doF
  xmonad . withSB mySB . ewmhFullscreen . ewmh . docks $ def
    {
      -- simple stuff
      terminal           = myTerminal
    , focusFollowsMouse  = myFocusFollowsMouse
    , clickJustFocuses   = myClickJustFocuses
    , borderWidth        = myBorderWidth
    , modMask            = myModMask
    , workspaces         = myWorkspaces
    , normalBorderColor  = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor

      -- key bindings
    , keys               = myKeys
    , mouseBindings      = myMouseBindings

      -- hooks, layouts
    , layoutHook         = myLayout
    , manageHook         = myManageHook
    , handleEventHook    = myHandleEventHook
    , logHook            = activateLogHook acMh <+> logHook def
    , startupHook        = myStartupHook
    }

------------------------------------------------------------------------

-- | Finally, a copy of the default bindings in simple textual tabular format.
help :: String
help = unlines
  [ "The default modifier key is 'super'. Default keybindings:"
  , ""
  , "-- launching and killing programs"
  , "mod-Shift-Enter      Launch terminal"
  , "mod-p                Launch XPrompt (Xmonad Prompt)"
  , "mod-c                Launch greenclip with rofi"
  --, "Alt-p                Launch dmenu"
  --, "Alt-c                Launch greenclip with dmenu"
  --, "mod-Shift-p          Launch gmrun"
  , "mod-Shift-c          Close/kill the focused window"
  , "mod-Space            Rotate through the available layout algorithms"
  , "mod-Shift-Space      Reset the layouts on the current workSpace to default"
  , "mod-n                Resize/refresh viewed windows to the correct size"
  , ""
  , "-- move focus up or down the window stack"
  , "mod-Tab              Move focus to the next window"
  , "mod-Shift-Tab        Move focus to the previous window"
  , "mod-j                Move focus to the next window"
  , "mod-k                Move focus to the previous window"
  , "mod-m                Move focus to the master window"
  , ""
  , "-- modifying the window order"
  , "mod-Return           Move the focused window to the master pane."
  , "mod-Shift-j          Swap the focused window with the next window"
  , "mod-Shift-k          Swap the focused window with the previous window"
  , ""
  , "-- resizing the master/slave ratio"
  , "mod-h                Shrink the master width"
  , "mod-l                Expand the master width"
  , "mod-a                Shrink the master height"
  , "mod-s                Expand the master height"
  , ""
  , "-- increase or decrease spacing (gaps)"
  , "mod-g                Toggle spacing/gaps"
  , "mod-i                Increment both screen and window borders"
  , "mod-d                Deincrement both screen and window borders"
  , "Alt-i                Increment screen borders"
  , "Alt-d                Deincrement screen borders"
  , "Alt-Shift-i          Increment window borders"
  , "Alt-Shift-d          Deincrement window borders"
  , ""
  , "-- floating layer support"
  , "mod-t                Push window back into tiling; unfloat and re-tile it"
  , ""
  , "-- increase or decrease number of windows in the master area"
  , "mod-comma  (mod-,)   Increment the number of windows in the master area"
  , "mod-period (mod-.)   Deincrement the number of windows in the master area"
  , ""
  , "-- quit, or restart"
  , "mod-Shift-q          Quit xmonad"
  , "mod-q                Restart xmonad"
  , ""
  , "-- Workspaces & screens"
  , "mod-[1..9]           Switch to workSpace N"
  , "mod-Shift-[1..9]     Move client to workspace N"
  , "mod-Control-[1..9]   Move client and switch to workspace N"
  , "mod-{w,e,r}          Switch to physical/Xinerama screens 1, 2, or 3"
  , "mod-Shift-{w,e,r}    Move client to screen 1, 2, or 3"
  , "mod-Right            Switch to next workSpace"
  , "mod-Left             Switch to previous workSpace"
  , "mod-Shift-Right      Move client to next workSpace"
  , "mod-Shift-Left       Move client to previous workSpace"
  , "mod-f                Switch to a free workSpace"
  , "mod-z                Switch between previously used workSpace"
  , ""
  , "-- Mouse bindings: default actions bound to mouse events"
  , "mod-button1          Set the window to floating mode and move by dragging"
  , "mod-button2          Raise the window to the top of the stack"
  , "mod-button3          Set the window to floating mode and resize by dragging"
  , ""
  , "-- Switch layouts"
  , "Alt-t                Switch to 'Tall' layout"
  , "Alt-c                Switch to 'ThreeColMid' layout"
  , "Alt-f                Switch to 'Full' layout"
  , ""
  , "-- Sublayout bindings"
  , "mod-Ctrl-h           Merge with left client"
  , "mod-Ctrl-l           Merge with right client"
  , "mod-Ctrl-k           Merge with upper client"
  , "mod-Ctrl-j           Merge with lower client"
  , "mod-Ctrl-Space       Switch to next sublayout"
  , "mod-Ctrl-m           Merge all available clients on the workspace"
  , "mod-Ctrl-u           Unmerge currently focused client"
  , "mod-Ctrl-period (.)  Move focus to the next window in the sublayout"
  , "mod-Ctrl-comma (,)   Move focus to the previous window in the sublayout"
  , ""
  , "-- Shortcuts for taking screenshots"
  , "Print                Take fullscreen screenshot"
  , "Shift-Print          Take screenshot of selected screen"
  , "Ctrl-Print           Take screenshot of focused window"
  , ""
  , "-- Application"
  , "All-e                Open emacs-client"
  , "Alt-F9               Turn on/off picom"
  ]

-- vim:ft=haskell:expandtab
