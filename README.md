__This branch is known to be compatible with Xcode 4.0.2. For support for newer versions, see the master branch.__

To install all of the plugins, open XCFixins.xcworkspace and build it. To install a plugin individually, open its respective project and build it. In both cases, the plugins will be installed automatically as a part of the build process. Xcode must be relaunched for the plugins to take effect.

Plugins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__Note:__ If you installed a previous version of any of these plugins (before the XCFixin_ prefix was introduced) you should delete the old versions manually from ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__XCFixin_DisableAnimations__: This plugin disable's Xcode's various NSAnimation-based animations. For example, the Show/Hide Debug Area, Show/Hide Navigator, and Show/Hide Utilities animations are disabled with this plugin.

__XCFixin_DisableWriteStateData__: This plugin greatly improves Xcode's responsiveness by disabling the -[IDEWorkspaceDocument writeStateData] method. This method is of course undocumented and I'm unsure what data it typically writes. In my testing, I've noticed this plugin prevents the active source file from being remembered across Xcode launches, and it's very likely that it prevents other data from being written as well. I consider this plugin experimental and as such it is not installed automatically when building the XCFixins workspace; you must build this plugin individually to install it. With that said, on my machine this plugin *really* improves Xcode's responsiveness!

__XCFixin_FindFix__: By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This plugin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This plugin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

__XCFixin_HideDistractions__: This plugin adds a new "Hide Distractions" menu item to the View menu, which hides auxiliary views in the active source-editing window. This plugin groups various operations into a single menu item, including: View > Hide Toolbar, View > Hide Debug Area, View > Navigators > Hide Navigator, View > Utilities > Hide Utilities, and View > Editor > Standard. Additionally, this menu item maximizes the active window to fill the available screen area. This plugin works best when the XCFixin_DisableAnimations plugin is also installed.

__XCFixin_InhibitTabNextPlaceholder__: This plugin disables using the tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. Xcode's default tab functionality can be annoying if you've synthesized a method invocation and attempt to indent something nearby before filling-in the argument placeholders; in such a case, Xcode jumps to the nearest argument placeholder instead of indenting. This plugin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.