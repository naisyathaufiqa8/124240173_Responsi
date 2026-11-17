import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WishlistSwipeItem extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onDismiss;

  const WishlistSwipeItem({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  @override
  State<WishlistSwipeItem> createState() => _WishlistSwipeItemState();
}

class _WishlistSwipeItemState extends State<WishlistSwipeItem> {
  static const double _dismissThreshold = 88;
  static const Duration _settleDuration = Duration(milliseconds: 180);
  static const Duration _scrollIdleDuration = Duration(milliseconds: 350);

  double _offset = 0;
  double _itemWidth = 0;
  bool _isDragging = false;
  bool _isDismissing = false;
  bool _isPanZooming = false;
  Timer? _scrollResetTimer;

  @override
  void dispose() {
    _scrollResetTimer?.cancel();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _isDismissing || _isPanZooming) return;

    final delta = event.scrollDelta;
    if (delta.dx.abs() <= delta.dy.abs()) {
      _settle();
      return;
    }
    _applyHorizontalDelta(delta.dx, isDragging: false, resetAfterIdle: true);
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_isDismissing) return;

    final delta = event.panDelta;
    if (delta.dx.abs() <= delta.dy.abs()) {
      _settle();
      return;
    }
    _applyHorizontalDelta(delta.dx, isDragging: true);
  }

  void _applyHorizontalDelta(
    double delta, {
    required bool isDragging,
    bool resetAfterIdle = false,
  }) {
    if (_isDismissing || delta == 0) return;
    _scrollResetTimer?.cancel();

    setState(() {
      _isDragging = isDragging;
      _offset = (_offset + delta).clamp(-_itemWidth, 0).toDouble();
    });

    if (_offset <= -_dismissThreshold) {
      _dismiss();
    } else if (resetAfterIdle) {
      _scrollResetTimer = Timer(_scrollIdleDuration, _settle);
    }
  }

  void _settle() {
    _scrollResetTimer?.cancel();
    if (!mounted || _isDismissing || (_offset == 0 && !_isDragging)) return;
    setState(() {
      _isDragging = false;
      _offset = 0;
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _scrollResetTimer?.cancel();
    setState(() {
      _isDismissing = true;
      _isDragging = false;
      _offset = -_itemWidth;
    });

    await Future<void>.delayed(_settleDuration);
    if (!mounted) return;

    final removed = await widget.onDismiss();
    if (!mounted || removed) return;
    setState(() {
      _isDismissing = false;
      _offset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _itemWidth = constraints.maxWidth;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerSignal: _handlePointerSignal,
          onPointerPanZoomStart: (_) {
            _isPanZooming = true;
            _scrollResetTimer?.cancel();
          },
          onPointerPanZoomUpdate: _handlePanZoomUpdate,
          onPointerPanZoomEnd: (_) {
            _isPanZooming = false;
            _settle();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            supportedDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
            },
            onHorizontalDragStart: (_) {
              _scrollResetTimer?.cancel();
              setState(() => _isDragging = true);
            },
            onHorizontalDragUpdate: (details) =>
                _applyHorizontalDelta(details.delta.dx, isDragging: true),
            onHorizontalDragEnd: (_) => _settle(),
            onHorizontalDragCancel: _settle,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.wishlistRemove,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : _settleDuration,
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(_offset, 0, 0),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
