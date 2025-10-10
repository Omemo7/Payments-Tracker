import 'package:flutter/material.dart';

/// A reusable Scaffold that ensures bottom safe area across the app.
/// - Keeps top = false (AppBar already handles the status bar).
/// - Ensures bottom = true so content never hides behind gesture areas.
/// - Also wraps bottomNavigationBar & persistentFooterButtons in a SafeArea.
class SafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final List<Widget>? persistentFooterButtons;
  final Color? backgroundColor;
  final Drawer? drawer;
  final Drawer? endDrawer;
  final bool extendBody;              // e.g., if you have a translucent bottom bar
  final bool extendBodyBehindAppBar;  // keep false in most cases

  const SafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.persistentFooterButtons,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,   // AppBar already offsets the status bar
      bottom: true, // protect against system nav / home indicator
      child: Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        drawer: drawer,
        endDrawer: endDrawer,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,

        // Ensure anything docked at the bottom respects the safe area too
        bottomNavigationBar: bottomNavigationBar == null
            ? null
            : SafeArea(
          top: false,
          bottom: true,
          // add a tiny minimum padding so it never sticks to the edge
          minimum: const EdgeInsets.only(bottom: 6),
          child: bottomNavigationBar!,
        ),

        persistentFooterButtons: persistentFooterButtons == null
            ? null
            : [
          // Wrap footer buttons as a group so they float above gesture areas
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: persistentFooterButtons!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
