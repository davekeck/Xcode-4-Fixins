__This branch is known to be compatible with Xcode 4.3 and 4.3.2. For Xcode 4.0.2 support, see the xcode_402 branch.__

__===== PROJECT DESCRIPTION =====__

This project includes plugins that extend Xcode and fix some of its annoying behaviors, known as _fixins_.

__===== INSTALLATION =====__

To install all of the stable fixins, open XCFixins.xcworkspace and build it, and the fixins will automatically be installed as a part of the build process. Experimental fixins must be installed individually by building their respective projects found in the _À La Carte Projects_ directory.

Xcode must be relaunched for the fixins to take effect.

Fixins are installed into ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/.

__===== STABLE FIXINS =====__

__DisableAnimations__: This fixin disables Xcode's various NSAnimation-based animations. For example, the Show/Hide Debug Area, Show/Hide Navigator, and Show/Hide Utilities animations are disabled with this fixin.

__FindFix__: By default, when Xcode's inline find bar opens, it doesn't display any options to customize searching. This fixin makes Xcode show all find options (such as "Ignore Case") in the find bar when it opens. This fixin also makes text-replacement the default mode in the inline find bar, giving immediate access to the "Replace" and "Replace All" buttons.

__HideDistractions__: This fixin adds a new "Hide Distractions" menu item to the View menu, which hides auxiliary views in the active source-editing window. This fixin groups various operations into a single menu item, including: View > Hide Toolbar, View > Hide Debug Area, View > Navigators > Hide Navigator, View > Utilities > Hide Utilities, and View > Editor > Standard. Additionally, this menu item maximizes the active window to fill the available screen area. This fixin works best when the XCFixin_DisableAnimations fixin is also installed.

In Xcode 4.3, the Navigate > Jump to Instruction Pointer menu item interferes with the default 'Hide Distractions' key combination (command-shift-D). To resolve the conflict, change the 'Jump to Instruction Pointer' key combination in the Xcode preferences, or change the 'Hide Distractions' key combination in the fixin source.

__InhibitTabNextPlaceholder__: This fixin disables using the tab key to select between argument placeholders of a synthesized (by Xcode's code completion) method call. Xcode's default tab functionality can be annoying if you've synthesized a method invocation and attempt to indent something nearby before filling-in the argument placeholders; in such a case, Xcode jumps to the nearest argument placeholder instead of indenting. This fixin does not affect the "Jump to Next Placeholder" key binding in the Xcode preferences.

__OptionClickDocumentation__: This fixin changes Xcode's behavior when option-clicking a symbol, by opening the documentation for the given symbol rather than opening the Quick Help popup. (Normally this behavior is accessed by option-clicking a symbol and then clicking the book icon in the Quick Help popup.) Note that this fixin is necessary because option-double-clicking a symbol doesn't display the documentation for the symbol - it just opens the documentation dialog with the symbol entered into the search field.

__===== EXPERIMENTAL FIXINS =====__

These fixins must be built individually to be installed; see their individual projects in the _À La Carte Projects_ directory.

__DisableWriteStateData__: This fixin improves Xcode's responsiveness by disabling the -[IDEWorkspaceDocument writeStateData] method. This method is of course undocumented and I'm unsure what data it typically writes. In my testing, I've noticed this fixin prevents the active source file from being remembered across Xcode launches, and it's very likely that it prevents other data from being written as well. With that said, on my machine this fixin really improves Xcode's responsiveness.

__UserScripts__: Reinstates some semblance of the Xcode 3.x User Scripts menu. See documentation in the XCFixin_UserScripts directory. __You must build this fixin individually to install it.__