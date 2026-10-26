import 'package:flutter/widgets.dart';

/// True when the widget's screen is the one the user is looking at: not a tab kept alive in the
/// background, and not covered by another page (e.g. Sign in pushed on top).
/// Screens only load data when this is true, so nothing is fetched for screens nobody sees.
/// Reading it also rebuilds the widget when that changes (switching tabs, closing the page on top).
bool isOnScreen(BuildContext context) => TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? true);

/// Runs [load] after this frame, but only while the screen is on screen (see [isOnScreen]).
void loadWhenOnScreen(BuildContext context, VoidCallback load) {
  if (!isOnScreen(context)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted && isOnScreen(context)) load();
  });
}
