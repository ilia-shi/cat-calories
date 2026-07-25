import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A horizontal scroll strip that works with every pointer, not just a finger.
///
/// Two things Flutter does not give a plain horizontal [SingleChildScrollView]:
/// dragging with a mouse (desktop [ScrollBehavior.dragDevices] excludes
/// `PointerDeviceKind.mouse`, so a click-drag does nothing), and reacting to a
/// wheel — a mouse reports the wheel on the vertical axis, which a horizontal
/// viewport ignores unless the user holds shift. The wheel mapping yields to an
/// enclosing vertical scrollable, so it only applies where nothing else would
/// have used the wheel.
class HorizontalDragScrollArea extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HorizontalDragScrollArea({
    Key? key,
    required this.child,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  State<HorizontalDragScrollArea> createState() =>
      _HorizontalDragScrollAreaState();
}

class _HorizontalDragScrollAreaState extends State<HorizontalDragScrollArea> {
  static const Set<PointerDeviceKind> _dragDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };

  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) {
      return;
    }

    // Inside a scrolling page (a form, a bottom sheet) the wheel belongs to the
    // page: hovering a strip must not trap the wheel and strand the user
    // mid-screen. There, sideways movement comes from a drag or shift+wheel.
    if (Scrollable.maybeOf(context, axis: Axis.vertical) != null) {
      return;
    }

    // Register instead of scrolling outright: the inner Scrollable is hit-tested
    // first and claims the event whenever it can use the delta itself (a dx
    // wheel, or dy with the shift modifier held). The resolver then hands us
    // only what it declined — the plain vertical wheel — so a trackpad or a
    // horizontal wheel never scrolls twice.
    GestureBinding.instance.pointerSignalResolver
        .register(event, _scrollByPointerSignal);
  }

  void _scrollByPointerSignal(PointerSignalEvent event) {
    final scrollDelta = (event as PointerScrollEvent).scrollDelta;
    final position = _controller.position;
    final delta = scrollDelta.dy != 0 ? scrollDelta.dy : scrollDelta.dx;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: ScrollConfiguration(
        behavior:
            ScrollConfiguration.of(context).copyWith(dragDevices: _dragDevices),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
