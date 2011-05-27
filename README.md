To install either plugin, open the respective Xcode project and build it. The plugin will be installed automatically as a part of the build process. Xcode must be relaunched for the plugin to take effect.

Plugins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__FindFix__: By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This plugin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This plugin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

__InhibitTabNextPlaceholder__: This plugin disables using the Tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. This plugin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.