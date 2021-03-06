{-# LANGUAGE LambdaCase #-}

--
-- xmonad config file.
--
-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.
--
-- Normally, you'd only override those defaults you care about.
--

-- Base
import Control.Monad (join, liftM, when, (>=>))
import qualified Data.Map as M
import Data.Maybe (fromJust, maybeToList)
import Data.Monoid
import System.Exit
import System.IO (Handle)
import XMonad hiding ((|||))
-- Actions
import XMonad.Actions.CycleWS
import XMonad.Actions.Promote
-- Hooks
import XMonad.Hooks.DynamicLog (PP (..), dynamicLogWithPP, shorten, wrap, xmobarColor, xmobarPP)
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks (ToggleStruts (..), avoidStruts, docks, manageDocks)
import XMonad.Hooks.ManageHelpers (doCenterFloat, doFullFloat, isDialog, isFullscreen)
import XMonad.Hooks.UrgencyHook (UrgencyHook, urgencyHook, withUrgencyHook)
-- Layout
import XMonad.Layout.Accordion
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.WindowNavigation
import qualified XMonad.StackSet as W
-- Util
import XMonad.Util.Cursor (setDefaultCursor)
import XMonad.Util.NamedScratchpad
import XMonad.Util.NamedWindows (getName)
import XMonad.Util.Run (hPutStrLn, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce (spawnOnce)

--import XMonad.Util.EZConfig (additionalKeys)

-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal = "alacritty"

-- My launcher
--
myLauncher = "rofi -theme ~/.config/rofi/themes/slate.rasi -width 624 -lines 12"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth = 2

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask = mod4Mask

-- Alternative modkey
--
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
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

-- Enable clickable workspaces
--
myWorkspaceIndices = M.fromList $ zip myWorkspaces [1 ..] -- (,) == \x y -> (x,y)

clickable ws = "<action=xdotool key super+" ++ show i ++ ">" ++ ws ++ "</action>"
  where
    i = fromJust $ M.lookup ws myWorkspaceIndices

-- Get count of available windows on a workspace
--
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor = "#282c34"

myFocusedBorderColor = "#366799"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys conf@XConfig {XMonad.modMask = modm} =
  M.fromList $
    [ -- launch a terminal
      ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf),
      -- launch dmenu
      ((altMask, xK_p), spawn "dmenu_run -p 'Run:' -w 1916"),
      -- launch greenclip-dmenu
      ((altMask, xK_c), spawn "greenclip print | sed '/^$/d' | dmenu -s -l 10 -g 2 -w 1916 -p 'Clipboard:' | xargs -r -d'\n' -I '{}' greenclip print '{}'"),
      -- launch rofi
      ((modm, xK_p), spawn (myLauncher ++ " -show drun -show-icons")),
      -- launch rofi-greenclip
      ((modm, xK_c), spawn (myLauncher ++ " -show Clipboard -modi 'Clipboard:greenclip print' -run-command '{cmd}'")),
      -- launch gmrun
      -- ((modm .|. shiftMask, xK_p ), spawn "gmrun"),
      -- close focused window
      ((modm .|. shiftMask, xK_c), kill),
      -- Rotate through the available layout algorithms
      ((modm, xK_space), sendMessage NextLayout),
      --  Reset the layouts on the current workspace to default
      ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
      -- Resize viewed windows to the correct size
      ((modm, xK_n), refresh),
      -- Move focus to the next window
      ((modm, xK_Tab), windows W.focusDown),
      -- Move focus to the next window
      ((modm, xK_j), windows W.focusDown),
      -- Move focus to the previous window
      ((modm, xK_k), windows W.focusUp),
      -- Move focus to the master window
      ((modm, xK_m), windows W.focusMaster),
      -- Swap the focused window and the master window
      ((modm, xK_Return), windows W.swapMaster),
      -- Swap the focused window with the next window
      ((modm .|. shiftMask, xK_j), windows W.swapDown),
      -- Swap the focused window with the previous window
      ((modm .|. shiftMask, xK_k), windows W.swapUp),
      -- Shrink the master area
      ((modm, xK_h), sendMessage Shrink),
      -- Expand the master area
      ((modm, xK_l), sendMessage Expand),
      -- Shrink focused windows height
      ((modm, xK_a), sendMessage MirrorShrink),
      -- Expand focused windows height
      ((modm, xK_s), sendMessage MirrorExpand),
      -- Push window back into tiling
      ((modm, xK_t), withFocused $ windows . W.sink),
      -- Increment the number of windows in the master area
      ((modm, xK_comma), sendMessage (IncMasterN 1)),
      -- Deincrement the number of windows in the master area
      ((modm, xK_period), sendMessage (IncMasterN (-1))),
      -- Toggle the status bar gap
      -- Use this binding with avoidStruts from Hooks.ManageDocks.
      -- See also the statusBar function from Hooks.DynamicLog.
      --
      ((modm, xK_b), sendMessage ToggleStruts),
      -- Quit xmonad
      ((modm .|. shiftMask, xK_q), io exitSuccess),
      -- Restart xmonad
      ((modm, xK_q), spawn "xmonad --recompile; xmonad --restart"),
      -- Moves the focused window to the master pane
      ((modm, xK_Return), promote),
      -- Run xmessage with a summary of the default keybindings (useful for beginners)
      ((modm .|. shiftMask, xK_slash), spawn ("echo \"" ++ help ++ "\" | xmessage -file -")),
      -- A basic CycleWS setup
      ((modm, xK_Right), nextWS),
      ((modm, xK_Left), prevWS),
      ((modm .|. shiftMask, xK_Right), shiftToNext),
      ((modm .|. shiftMask, xK_Left), shiftToPrev),
      ((modm, xK_z), toggleWS' ["NSP"]),
      ((modm, xK_f), moveTo Next EmptyWS), -- find a free workspace
      -- Increase/Decrease spacing (gaps)
      ((modm, xK_i), incScreenWindowSpacing 4),
      ((modm, xK_d), decScreenWindowSpacing 4),
      ((altMask, xK_i), incScreenSpacing 4),
      ((altMask, xK_d), decScreenSpacing 4),
      ((altMask .|. shiftMask, xK_i), incWindowSpacing 4),
      ((altMask .|. shiftMask, xK_d), decWindowSpacing 4),
      -- Screenshot shortcuts (Requires: maim & xclip)
      ((0, xK_Print), spawn "$HOME/.config/xmonad/scripts/msclip -f"),
      ((0 .|. controlMask, xK_Print), spawn "$HOME/.config/xmonad/scripts/msclip -w"),
      ((0 .|. shiftMask, xK_Print), spawn "$HOME/.config/xmonad/scripts/msclip -s"),
      -- SubLayouts
      ((modm .|. controlMask, xK_h), sendMessage $ pullGroup L),
      ((modm .|. controlMask, xK_l), sendMessage $ pullGroup R),
      ((modm .|. controlMask, xK_k), sendMessage $ pullGroup U),
      ((modm .|. controlMask, xK_j), sendMessage $ pullGroup D),
      ((modm .|. controlMask, xK_space), toSubl NextLayout),
      ((modm .|. controlMask, xK_m), withFocused (sendMessage . MergeAll)),
      ((modm .|. controlMask, xK_u), withFocused (sendMessage . UnMerge)),
      ((modm .|. controlMask, xK_comma), onGroup W.focusUp'),
      ((modm .|. controlMask, xK_period), onGroup W.focusDown'),
      -- Scratchpad
      ((modm .|. controlMask, xK_Return), namedScratchpadAction myScratchpads "terminal"),
      -- Picom on/off
      ((altMask, xK_F9), spawn "killall picom || picom --experimental-backends -b"),
      -- Easily switch your layouts
      ((altMask, xK_t), sendMessage $ JumpToLayout "tiled"),
      ((altMask, xK_c), sendMessage $ JumpToLayout "center"),
      ((altMask, xK_f), sendMessage $ JumpToLayout "full")
    ]
      ++
      --
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      --
      [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]
      ++
      --
      -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
      -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
      --
      [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
          (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
      ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings XConfig {XMonad.modMask = modm} =
  M.fromList
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ( (modm, button1),
        \w ->
          focus w >> mouseMoveWindow w
            >> windows W.shiftMaster
      ),
      -- mod-button2, Raise the window to the top of the stack
      ((modm, button2), \w -> focus w >> windows W.shiftMaster),
      -- mod-button3, Set the window to floating mode and resize by dragging
      ( (modm, button3),
        \w ->
          focus w >> mouseResizeWindow w
            >> windows W.shiftMaster
      )
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

------------------------------------------------------------------------
-- Spacing (gaps)
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
-- Tabbed layout config
myTabConfig =
  def
    { activeColor = "#366799",
      activeBorderColor = "#366799",
      activeTextColor = "#eceff4",
      inactiveColor = "#282c34",
      inactiveBorderColor = "#282c34",
      inactiveTextColor = "#4c566a",
      urgentColor = "#282c34",
      urgentBorderColor = "#282c34",
      urgentTextColor = "#ebcb8b",
      fontName = "xft:JetBrains Mono:style=Bold:size=10:antialias=true:hinting=true"
    }

myLayout =
  avoidStruts $
    lessBorders OnlyScreenFloat $
      tiled
        ||| mtiled
        ||| center
        ||| full
        ||| tabs
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled =
      renamed [Replace "tiled"] $
        windowNavigation $
          addTabs shrinkText myTabConfig $
            subLayout [] (Simplest ||| Accordion) $
              mySpacing 5 $
                ResizableTall nmaster delta ratio []

    mtiled =
      renamed [Replace "mtiled"] $
        windowNavigation $
          addTabs shrinkText myTabConfig $
            subLayout [] (Simplest ||| Accordion) $
              mySpacing 5 $
                Mirror tiled

    center =
      renamed [Replace "center"] $
        windowNavigation $
          addTabs shrinkText myTabConfig $
            subLayout [] (Simplest ||| Accordion) $
              mySpacing 5 $
                ThreeColMid nmaster delta ratio

    full =
      renamed [Replace "full"] $
        noBorders Full

    tabs =
      renamed [Replace "tabs"] $
        tabbed shrinkText myTabConfig

    -- The default number of windows in the master pane
    nmaster = 1

    -- Default proportion of screen occupied by master pane
    ratio = 1 / 2

    -- Percent of screen to increment by when resizing panes
    delta = 3 / 100

------------------------------------------------------------------------
-- Scratchpad
--
myScratchpads =
  [ -- run a terminal inside scratchpad
    NS "terminal" spawnTerm findTerm manageTerm
  ]
  where
    spawnTerm = myTerminal ++ " --class scratchpad"
    findTerm = resource =? "scratchpad"
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
myManageHook =
  composeAll
    [ className =? "MPlayer" --> doFloat,
      resource =? "desktop_window" --> doIgnore,
      resource =? "kdesktop" --> doIgnore,
      resource =? "Toolkit" <||> resource =? "Browser" --> doFloat,
      resource =? "redshift-gtk" --> doCenterFloat,
      isFullscreen --> doFullFloat,
      isDialog --> doCenterFloat
    ]
    <+> manageDocks
    <+> namedScratchpadManageHook myScratchpads

-- Fix for firefox fullscreen
--
-- from https://github.com/evanjs/gentoo-dotfiles/commit/cbf78364ea60e62466594340090d8e99200e8e08
addNETSupported x = withDisplay $ \dpy -> do
  r <- asks theRoot
  a_NET_SUPPORTED <- getAtom "_NET_SUPPORTED"
  a <- getAtom "ATOM"
  liftIO $ do
    sup <- join . maybeToList <$> getWindowProperty32 dpy a_NET_SUPPORTED r
    when (fromIntegral x `notElem` sup) $
      changeProperty32 dpy r a_NET_SUPPORTED a propModeAppend [fromIntegral x]

addEWMHFullscreen = do
  wms <- getAtom "_NET_WM_STATE"
  wfs <- getAtom "_NET_WM_STATE_FULLSCREEN"
  mapM_ addNETSupported [wms, wfs]

------------------------------------------------------------------------
-- Event handling

-- * EwmhDesktops users should change this to ewmhDesktopsEventHook

--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myEventHook = handleEventHook def <+> fullscreenEventHook

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
myLogHook xmproc =
  dynamicLogWithPP . namedScratchpadFilterOutWorkspacePP $
    xmobarPP
      { -- Xmobar workspace config
        --
        ppOutput = hPutStrLn xmproc,
        ppCurrent = xmobarColor "#ebcb8b" "" . wrap "[" "]", -- Current workspace
        ppLayout = \case
          "tiled" -> "[]="
          "mtiled" -> "TTT"
          "center" -> "|M|"
          "full" -> "[F]"
          "tabs" -> "[T]"
          _ -> "?",
        -- ppVisible = xmobarColor "#b48ead" "#434c5e" . wrap " " " " . clickable,  -- Visible but not current workspace (other monitor)
        ppHidden = xmobarColor "#d8dee9" "" . wrap "" "" . clickable, -- Hidden workspaces, contain windows
        -- ppHiddenNoWindows = xmobarColor "#4c566a" "" . clickable,  -- Hidden workspaces, no windows
        ppTitle = xmobarColor "#a3be8c" "" . shorten 50, -- Title of active window
        ppSep = "<fc=#434c5e> | </fc>", -- Separator
        ppUrgent = xmobarColor "#ff6c6b" "" . wrap "!" "!" . clickable, -- Urgent workspaces
        ppExtras = [windowCount], -- Number of windows in current workspace
        ppOrder = \(ws : l : t : ex) -> [ws, l] ++ ex ++ [t]
      }

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
myStartupHook = do
  setDefaultCursor xC_left_ptr
  spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x282c34  --height 22 --iconspacing 5 &"
  spawnOnce "feh --no-fehbg --bg-scale ~/Pictures/Wallpapers/0143.jpg"
  spawnOnce "nm-applet &"
  spawnOnce "picom --experimental-backends -b"
  spawnOnce "dunst &"
  spawnOnce "greenclip daemon &"
  spawnOnce "redshift-gtk &"
  -- spawn "systemctl --user restart redshift-gtk.service"
  -- spawnOnce "volumeicon &"
  spawnOnce "numlockx &"
  spawnOnce "ibus-daemon -drx"
  spawnOnce "light-locker &"

------------------------------------------------------------------------
-- Urgency hook
--
-- from https://pbrisbin.com/posts/using_notify_osd_for_xmonad_notifications/
data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
  urgencyHook LibNotifyUrgencyHook w = do
    name <- getName w
    Just idx <- W.findTag w <$> gets windowset

    safeSpawn "notify-send" [show name, "workspace " ++ idx]

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = do
  xmproc <- spawnPipe "xmobar ~/.config/xmonad/xmobar/xmobarrc"

  xmonad $
    ewmh $
      docks $
        withUrgencyHook
          LibNotifyUrgencyHook
          def
            { -- A structure containing your configuration settings, overriding
              -- fields in the default config. Any you don't override, will
              -- use the defaults defined in xmonad/XMonad/Config.hs
              --
              -- simple stuff
              terminal = myTerminal,
              focusFollowsMouse = myFocusFollowsMouse,
              clickJustFocuses = myClickJustFocuses,
              borderWidth = myBorderWidth,
              modMask = myModMask,
              workspaces = myWorkspaces,
              normalBorderColor = myNormalBorderColor,
              focusedBorderColor = myFocusedBorderColor,
              -- key bindings
              keys = myKeys,
              mouseBindings = myMouseBindings,
              -- hooks, layouts
              layoutHook = myLayout,
              manageHook = myManageHook,
              handleEventHook = myEventHook,
              logHook = myLogHook xmproc,
              startupHook = myStartupHook >> addEWMHFullscreen
            }

------------------------------------------------------------------------

-- | Finally, a copy of the default bindings in simple textual tabular format.
help =
  unlines
    [ "The default modifier key is 'super'. Default keybindings:",
      "",
      "-- launching and killing programs",
      "mod-Shift-Enter      Launch terminal",
      "mod-p                Launch rofi",
      "mod-c                Launch greenclip with rofi",
      "Alt-p                Launch dmenu",
      "Alt-c                Launch greenclip with dmenu",
      --"mod-Shift-p          Launch gmrun",
      "mod-Shift-c          Close/kill the focused window",
      "mod-Space            Rotate through the available layout algorithms",
      "mod-Shift-Space      Reset the layouts on the current workSpace to default",
      "mod-n                Resize/refresh viewed windows to the correct size",
      "",
      "-- move focus up or down the window stack",
      "mod-Tab              Move focus to the next window",
      "mod-Shift-Tab        Move focus to the previous window",
      "mod-j                Move focus to the next window",
      "mod-k                Move focus to the previous window",
      "mod-m                Move focus to the master window",
      "",
      "-- modifying the window order",
      "mod-Return           Swap the focused window and the master window",
      "mod-Shift-j          Swap the focused window with the next window",
      "mod-Shift-k          Swap the focused window with the previous window",
      "",
      "-- resizing the master/slave ratio",
      "mod-h                Shrink the master width",
      "mod-l                Expand the master width",
      "mod-a                Shrink the master height",
      "mod-s                Expand the master height",
      "",
      "-- increase or decrease spacing (gaps)",
      "mod-i                Increment both screen and window borders",
      "mod-d                Deincrement both screen and window borders",
      "Alt-i                Increment screen borders",
      "Alt-d                Deincrement screen borders",
      "Alt-Shift-i          Increment window borders",
      "Alt-Shift-d          Deincrement window borders",
      "",
      "-- floating layer support",
      "mod-t                Push window back into tiling; unfloat and re-tile it",
      "",
      "-- increase or decrease number of windows in the master area",
      "mod-comma  (mod-,)   Increment the number of windows in the master area",
      "mod-period (mod-.)   Deincrement the number of windows in the master area",
      "",
      "-- quit, or restart",
      "mod-Shift-q          Quit xmonad",
      "mod-q                Restart xmonad",
      "",
      "-- Workspaces & screens",
      "mod-[1..9]           Switch to workSpace N",
      "mod-Right            Switch to next workSpace",
      "mod-Left             Switch to previous workSpace",
      "mod-Shift-Right      Move client to next workSpace",
      "mod-Shift-Left       Move client to previous workSpace",
      "mod-f                Switch to a free workSpace",
      "mod-z                Switch between previously used workSpace",
      "mod-Shift-[1..9]     Move client to workspace N",
      "mod-{w,e,r}          Switch to physical/Xinerama screens 1, 2, or 3",
      "mod-Shift-{w,e,r}    Move client to screen 1, 2, or 3",
      "",
      "-- Mouse bindings: default actions bound to mouse events",
      "mod-button1          Set the window to floating mode and move by dragging",
      "mod-button2          Raise the window to the top of the stack",
      "mod-button3          Set the window to floating mode and resize by dragging",
      "",
      "-- Switch layouts",
      "Alt-t                Switch to 'Tall' layout",
      "Alt-c                Switch to 'ThreeColMid' layout",
      "Alt-f                Switch to 'Full' layout",
      "",
      "-- Sublayout bindings",
      "mod-Ctrl-h           Merge with left client",
      "mod-Ctrl-l           Merge with right client",
      "mod-Ctrl-k           Merge with upper client",
      "mod-Ctrl-j           Merge with lower client",
      "mod-Ctrl-Space       Switch to next sublayout",
      "mod-Ctrl-m           Merge all available clients on the workspace",
      "mod-Ctrl-u           Unmerge currently focused client",
      "mod-Ctrl-period (.)  Move focus to the next window in the sublayout",
      "mod-Ctrl-comma (,)   Move focus to the previous window in the sublayout",
      "",
      "-- Shortcuts for taking screenshots",
      "Print                Take fullscreen screenshot",
      "Shift-Print          Take screenshot of selected screen",
      "Ctrl-Print           Take screenshot of focused window",
      "",
      "-- Application",
      "Alt-F9               Turn on/off picom"
    ]
