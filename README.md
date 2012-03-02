__This branch is known to be compatible with Xcode 4.3. For Xcode 4.0.2 support, see the xcode_402 branch.__

__PROJECT DESCRIPTION__

This project includes plugins that extend Xcode and fix some of its annoying behaviors.

__INSTALLATION__

To install all of the plugins, open XCFixins.xcworkspace and build it, which will automatically install the plugins as a part of the build process. To install a plugin individually, open its respective project and build it.

Xcode must be relaunched for the plugins to take effect.

Plugins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__PLUGIN DESCRIPTIONS__

_DisableAnimations_: This plugin disables Xcode's various NSAnimation-based animations. For example, the Show/Hide Debug Area, Show/Hide Navigator, and Show/Hide Utilities animations are disabled with this plugin.

_DisableWriteStateData_: This plugin greatly improves Xcode's responsiveness by disabling the -[IDEWorkspaceDocument writeStateData] method. This method is of course undocumented and I'm unsure what data it typically writes. In my testing, I've noticed this plugin prevents the active source file from being remembered across Xcode launches, and it's very likely that it prevents other data from being written as well. I consider this plugin experimental and as such it is not installed automatically when building the XCFixins workspace; you must build this plugin individually to install it. With that said, on my machine this plugin *really* improves Xcode's responsiveness!

_FindFix_: By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This plugin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This plugin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

_HideDistractions_: This plugin adds a new "Hide Distractions" menu item to the View menu, which hides auxiliary views in the active source-editing window. This plugin groups various operations into a single menu item, including: View > Hide Toolbar, View > Hide Debug Area, View > Navigators > Hide Navigator, View > Utilities > Hide Utilities, and View > Editor > Standard. Additionally, this menu item maximizes the active window to fill the available screen area. This plugin works best when the XCFixin_DisableAnimations plugin is also installed.

In Xcode 4.3, the Navigate > Jump to Instruction Pointer menu item interferes with the default 'Hide Distractions' key combination (command-shift-D). To resolve the conflict, change the 'Jump to Instruction Pointer' key combination in the Xcode preferences, or change the 'Hide Distractions' key combination in the plugin source.

_InhibitTabNextPlaceholder_: This plugin disables using the tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. Xcode's default tab functionality can be annoying if you've synthesized a method invocation and attempt to indent something nearby before filling-in the argument placeholders; in such a case, Xcode jumps to the nearest argument placeholder instead of indenting. This plugin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.

_OptionClickDocumentation_: This plugin changes Xcode's behavior when option-clicking a symbol, by opening the documentation for the given symbol rather than opening the Quick Help popup. (Normally this behavior is found by option-clicking a symbol and then clicking the book icon in the Quick Help popup.) Note that this plugin is necessary because option-double-clicking a symbol doesn't display the documentation for the symbol - it just opens the documentation dialog with the symbol entered into the search field.