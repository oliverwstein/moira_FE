import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:moira/content/content.dart';

class TextEntry{
  String text; double offsetX; double offsetY; Anchor anchor;
  TextEntry(this.text, this.offsetX, this.offsetY, this.anchor);
}

class UnitInfoMenu extends Menu {
  final Unit unit;
  late final SpriteFontRenderer fontRenderer;
  UnitInfoMenu(this.unit);
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.camera.visibleWorldRect.toVector2(); // Dynamic size based on options
    anchor = Anchor.topLeft;
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont);
  }
  @override
  void update(dt){
    position = game.camera.visibleWorldRect.topLeft.toVector2();
  }
  @override
  void render(Canvas canvas) {
      super.render(canvas);
      if(game.stage.menuManager.last == this){
        size = game.camera.visibleWorldRect.toVector2();
        final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
        canvas.drawRect(size.toRect(), backgroundPaint);
        double lineHeight = Stage.tileSize * 0.75;
        List<TextEntry> bio = [
          TextEntry(unit.name, Stage.tileSize*.25, 0, Anchor.topLeft),
          TextEntry(unit.unitClass.name, Stage.tileSize*.25, lineHeight, Anchor.topLeft),
          TextEntry(unit.faction, Stage.tileSize*.25, lineHeight*2, Anchor.topLeft),
          TextEntry("Level:${unit.level}(${unit.exp})", Stage.tileSize*.25, lineHeight*3, Anchor.topLeft),
        ];
        List<TextEntry> vitals = [
          TextEntry("HP:${unit.hp}/${unit.getStat("hp")}", Stage.tileSize*.25, 0, Anchor.topLeft),
          TextEntry("STA:${unit.sta}/${unit.getStat("sta")}", Stage.tileSize*.25, lineHeight, Anchor.topLeft),
        ];
        List<TextEntry> stats = [
          TextEntry("Strength:", Stage.tileSize*.25, lineHeight*0, Anchor.topLeft),
          TextEntry("${unit.getStat("str")}", Stage.tileSize*6, lineHeight*0, Anchor.topRight),
          TextEntry("Defense:", Stage.tileSize*.25, lineHeight*1, Anchor.topLeft),
          TextEntry("${unit.getStat("def")}", Stage.tileSize*6, lineHeight*1, Anchor.topRight),
          TextEntry("Dexterity:", Stage.tileSize*.25, lineHeight*2, Anchor.topLeft),
          TextEntry("${unit.getStat("dex")}", Stage.tileSize*6, lineHeight*2, Anchor.topRight),
          TextEntry("Speed:", Stage.tileSize*.25, lineHeight*3, Anchor.topLeft),
          TextEntry("${unit.getStat("spe")}", Stage.tileSize*6, lineHeight*3, Anchor.topRight),
          TextEntry("Will:", Stage.tileSize*.25, lineHeight*4, Anchor.topLeft),
          TextEntry("${unit.getStat("wil")}", Stage.tileSize*6, lineHeight*4, Anchor.topRight),
          TextEntry("Wisdom:", Stage.tileSize*.25, lineHeight*5, Anchor.topLeft),
          TextEntry("${unit.getStat("wis")}", Stage.tileSize*6, lineHeight*5, Anchor.topRight),
          TextEntry("Luck:", Stage.tileSize*.25, lineHeight*6, Anchor.topLeft),
          TextEntry("${unit.getStat("lck")}", Stage.tileSize*6, lineHeight*6, Anchor.topRight),
        ];
        renderTextEntries(canvas, Vector2(0, 0), bio, fontRenderer, lineHeight);
        renderTextEntries(canvas, Vector2(0, Stage.tileSize*3), vitals, fontRenderer, lineHeight);
        renderTextEntries(canvas, Vector2(0, Stage.tileSize*5), stats, fontRenderer, lineHeight);
        if(game.portraitMap.keys.contains(unit.name)){
          add(SpriteComponent(sprite:game.portraitMap[unit.name]!, position: Vector2(Stage.tileSize*5, 0)));
        }
      }
  }
}
void renderTextEntries(Canvas canvas, Vector2 boxPosition, List<TextEntry> entries, SpriteFontRenderer fontRenderer, double lineHeight) {
  for (var entry in entries) {
    Vector2 absolutePosition = Vector2(boxPosition.x + entry.offsetX, boxPosition.y + entry.offsetY);
    fontRenderer.render(
      canvas,
      entry.text,
      absolutePosition,
      anchor: entry.anchor,
    );
  }
}