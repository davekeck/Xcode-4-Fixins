To install one of these plugins, open the respective Xcode project and build it. The plugin will be installed automatically as a part of the build process. Xcode must be relaunched for the plugin to take effect.

Plugins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__Note:__ If you installed a previous version of any of these plugins (before the XCFixin_ prefix was added to each project and product name) you should delete the old versions manually from ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__XCFixin_DisableAnimations__: This plugin disable's Xcode's various NSAnimation-based animations. For example, the Show/Hide Debug Area, Show/Hide Navigator, and Show/Hide Utilities animations are disabled with this plugin.

__XCFixin_FindFix__: By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This plugin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This plugin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

__XCFixin_HideDistractions__: This plugin adds a new "Hide Distractions" menu item to the View menu, which hides auxiliary views in the active source-editing window. Currently, this plugin groups the following operations into a single menu item: View > Hide Toolbar, View > Hide Debug Area, View > Navigators > Hide Navigator, View > Utilities > Hide Utilities, View > Editor > Standard. Additionally, this menu item maximizes the active window to fill the available screen area. This plugin works best when the XCFixin_DisableAnimations plugin is also installed.

__XCFixin_InhibitTabNextPlaceholder__: This plugin disables using the Tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. This plugin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.