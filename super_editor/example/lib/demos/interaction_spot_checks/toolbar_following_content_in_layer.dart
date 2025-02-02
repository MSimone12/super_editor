import 'dart:math';

import 'package:flutter/material.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:overlord/follow_the_leader.dart';
import 'package:overlord/overlord.dart';
import 'package:super_editor/super_editor.dart';

import 'spot_check_scaffold.dart';

class ToolbarFollowingContentInLayer extends StatefulWidget {
  const ToolbarFollowingContentInLayer({super.key});

  @override
  State<ToolbarFollowingContentInLayer> createState() => _ToolbarFollowingContentInLayerState();
}

class _ToolbarFollowingContentInLayerState extends State<ToolbarFollowingContentInLayer> {
  final _leaderLink = LeaderLink();
  final _viewportKey = GlobalKey();
  final _leaderBoundsKey = GlobalKey();

  final _baseContentWidth = 10.0;
  final _expansionExtent = ValueNotifier<double>(0);

  OverlayState? _ancestorOverlay;
  late final OverlayEntry _toolbarEntry;

  @override
  void initState() {
    super.initState();

    _toolbarEntry = OverlayEntry(builder: (_) {
      return _buildToolbarOverlay();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Any time our dependencies change, our ancestor Overlay may have changed.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final newOverlay = Overlay.of(context);
      if (newOverlay == _ancestorOverlay) {
        // Overlay didn't change. Nothing to do.
        return;
      }

      if (_ancestorOverlay != null) {
        _toolbarEntry.remove();
      }

      _ancestorOverlay = newOverlay;
      newOverlay.insert(_toolbarEntry);
    });
  }

  @override
  void dispose() {
    _toolbarEntry.remove();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpotCheckScaffold(
      content: KeyedSubtree(
        key: _viewportKey,
        child: ContentLayers(
          overlays: [
            (_) => LeaderLayoutLayer(
                  leaderLink: _leaderLink,
                  leaderBoundsKey: _leaderBoundsKey,
                ),
          ],
          content: (_) => Center(
            child: Column(
              children: [
                const Spacer(),
                ValueListenableBuilder(
                  valueListenable: _expansionExtent,
                  builder: (context, expansionExtent, _) {
                    return Container(
                      height: 12,
                      width: _baseContentWidth + (2 * expansionExtent) + 2, // +2 for border
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          key: _leaderBoundsKey,
                          width: _baseContentWidth + expansionExtent,
                          height: 10,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 96),
                TextButton(
                  onPressed: () {
                    _expansionExtent.value = Random().nextDouble() * 200;
                  },
                  child: Text("Change Size"),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarOverlay() {
    return FollowerFadeOutBeyondBoundary(
      link: _leaderLink,
      boundary: WidgetFollowerBoundary(
        boundaryKey: _viewportKey,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      child: Follower.withAligner(
        link: _leaderLink,
        aligner: CupertinoPopoverToolbarAligner(_viewportKey),
        child: CupertinoPopoverToolbar(
          focalPoint: LeaderMenuFocalPoint(link: _leaderLink),
          children: [
            CupertinoPopoverToolbarMenuItem(
              label: 'Cut',
              onPressed: () {
                print("Pressed 'Cut'");
              },
            ),
            CupertinoPopoverToolbarMenuItem(
              label: 'Copy',
              onPressed: () {
                print("Pressed 'Copy'");
              },
            ),
            CupertinoPopoverToolbarMenuItem(
              label: 'Paste',
              onPressed: () {
                print("Pressed 'Paste'");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderLayoutLayer extends ContentLayerStatefulWidget {
  const LeaderLayoutLayer({
    super.key,
    required this.leaderLink,
    required this.leaderBoundsKey,
  });

  final LeaderLink leaderLink;
  final GlobalKey leaderBoundsKey;

  @override
  ContentLayerState<ContentLayerStatefulWidget, Rect> createState() => LeaderLayoutLayerState();
}

class LeaderLayoutLayerState extends ContentLayerState<LeaderLayoutLayer, Rect> {
  @override
  Rect? computeLayoutData(Element? contentElement, RenderObject? contentLayout) {
    final boundsBox = widget.leaderBoundsKey.currentContext?.findRenderObject() as RenderBox?;
    if (boundsBox == null) {
      return null;
    }

    return Rect.fromLTWH(0, 0, boundsBox.size.width, boundsBox.size.height);
  }

  @override
  Widget doBuild(BuildContext context, Rect? layoutData) {
    if (layoutData == null) {
      return const SizedBox();
    }

    return Center(
      child: SizedBox(
        width: layoutData.size.width * 2,
        height: layoutData.size.height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Leader(
            link: widget.leaderLink,
            child: SizedBox.fromSize(
              size: layoutData.size,
              child: ColoredBox(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
