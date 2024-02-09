import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:moira/content/content.dart';
class UnitInfoPage extends Menu {
  final Unit unit;
  late final SpriteFontRenderer fontRenderer;
  UnitInfoPage(this.unit);
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.camera.visibleWorldRect.toVector2(); // Dynamic size based on options
    anchor = Anchor.topLeft;
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont);
  }
  @override
  void render(Canvas canvas) {
      super.render(canvas);
      if(game.stage.menuManager.last == this){
        size = game.camera.visibleWorldRect.toVector2();
        final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
        final highlightPaint = Paint()..color = const Color.fromARGB(141, 203, 16, 203); // Color for highlighting selected action
        canvas.drawRect(size.toRect(), backgroundPaint);
        double lineHeight = Stage.tileSize * 0.75;
      }
  }
}