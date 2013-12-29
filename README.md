__These plugins are known to be compatible with Xcode 4.5.2. Most are
compatible with Xcode 5. For Xcode 4.0.2 support, see the xcode_402
branch.__

__===== DESCRIPTION =====__

This project includes plugins (known as _fixins_) that extend Xcode and fix some of its annoying behaviors.

__===== INSTALLATION (Xcode 5) =====__

Despite the name, some of the Xcode 4 Fixins are compatible with
Xcode 5. Xcode 5 support is still under development.

To install the fixins:

1. Open the XCFixins workspace
2. Change the scheme to Build All Fixins
3. Build the fixins

The fixins will automatically be installed as a part of the build
process. Xcode must be relaunched for the fixins to take effect.

Fixins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__===== INSTALLATION (Xcode 4) =====__

To install a fixin:

1. Open the XCFixins workspace
2. Change the scheme to the fixin you want to install
3. Build the scheme (command-B)

The fixin will automatically be installed as a part of the build process. Xcode must be relaunched for the fixins to take effect.

Fixins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__===== THE FIXINS =====__

__CurrentLineHighlighter__ (_Xcode 4 only_): This fixin highlights the line currently being edited in the source editor, making it easier to track the current insertion point. This fixin adds a "Current Line Highlight Color..." menu item to the Editor menu to set the highlight color.

__DisableAnimations__: This fixin disables Xcode's various NSAnimation-based animations, such as the Show/Hide Debug Area, Show/Hide Navigator, and Show/Hide Utilities animations.

__FindFix__ (_Xcode 4 only_): By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This fixin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This fixin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

__HideDistractions__: This fixin adds a "Hide Distractions" menu item to the View menu, which focuses the current editor by hiding auxiliary views and maximizing the active window. This fixin works best when the XCFixin_DisableAnimations fixin is also installed.

The default key combination for the 'Hide Distractions' menu item is command-shift-D, which interferes with Xcode's default key combination for 'Jump to Instruction Pointer' (under the Navigate menu), so you may want remove that key binding to free up command-shift-D. Alternatively, you can modify the 'Hide Distractions' key combination by editing XCFixin_HideDistractions.m and changing the kHideDistractionsKey and kHideDistractionsKeyModifiers constants at the top of the file.

__InhibitTabNextPlaceholder__: This fixin disables using the tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. Xcode's default tab functionality can be annoying if you've synthesized a method invocation and attempt to indent something nearby before filling-in the argument placeholders; in such a case, Xcode jumps to the nearest argument placeholder instead of indenting. This fixin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.

__TabAcceptsCompletion__: Upon pressing tab, this fixin makes Xcode accept the currently-highlighted completion suggestion in the popup list. (Xcode's default tab behavior accepts only as much of the highlighted completion that is common amongst other suggestions.)

__UserScripts__: Reinstates some semblance of the Xcode 3.x User Scripts menu. See documentation in the XCFixin_UserScripts directory.

__CustomizeWarningErrorHighlights__: Customize the inline error/warning message highlight color. Useful if want to be able to read your code when using a dark background color.
