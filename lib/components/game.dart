import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart';

import 'background.dart';
import 'enemy.dart';
import 'ground.dart';
import 'brick.dart';
import 'player.dart';

class MyPhysicsGame extends Forge2DGame {
  MyPhysicsGame()
      : super(
          gravity: Vector2(0, 10),
          camera: CameraComponent.withFixedResolution(width: 800, height: 600),
        );

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  var backgroundImagePng = "";
  var groundImagePng = "";

  void createWorld() {
    int randomNumber = _random.nextInt(2);
    
    switch (randomNumber) {
      case 0:
        backgroundImagePng = 'colored_shroom.png';
        groundImagePng = 'dirt.png';
        break;
      case 1:
        backgroundImagePng = 'colored_grass.png';
        groundImagePng = 'grass.png';
        break;
      case 2:
        backgroundImagePng = 'colored_desert.png';
        groundImagePng = 'sand.png';
        break;
      default:
        backgroundImagePng = 'colored_shroom.png';
        groundImagePng = 'dirt.png';
    }
  }

  @override
  FutureOr<void> onLoad() async {
    createWorld();

    final backgroundImage = await images.load(backgroundImagePng);
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    unawaited(addEnemies().then((_) => addBricks()));
    await addPlayer();

    return super.onLoad();
  }

  Future<void> addGround() {
    return world.addAll([
      for (var x = camera.visibleWorldRect.left;
          x < camera.visibleWorldRect.right + groundSize;
          x += groundSize)
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite(groundImagePng),
        ),
    ]);
  }

  final _random = Random();

  Future<void> addBricks() async {
    for (var i = 0; i < 3; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 5 - 2.5),
              0),
          sprites: brickFileNames(type, size).map(
            (key, filename) => MapEntry(
              key,
              elements.getSprite(filename),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async => world.add(
        Player(
          Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
          aliens.getSprite(PlayerColor.randomColor.fileName),
        ),
      );

  @override
  void update(double dt) {
    super.update(dt);

    for (final enemy in world.children.whereType<Enemy>()) {
      if (enemy.position.y > camera.visibleWorldRect.bottom) {
        enemy.removeFromParent();
      }
    }

    for (final brick in world.children.whereType<Brick>()) {
      if (brick.position.y > camera.visibleWorldRect.bottom) {
        brick.removeFromParent();
      }
    }

    if (isMounted &&
        world.children.whereType<Player>().isEmpty &&
        (world.children.whereType<Brick>().isNotEmpty ||
            world.children.whereType<Enemy>().isNotEmpty)) {
      addPlayer();
    }
    if (isMounted &&
        enemiesFullyAdded &&
        world.children.whereType<Enemy>().isEmpty &&
        world.children.whereType<Brick>().isEmpty &&
        world.children.whereType<TextComponent>().isEmpty) {
      world.addAll(
        [
          (
            position: Vector2(0.5, 0.5),
            color: const Color.fromARGB(255, 114, 210, 140)
          ),
          (
            position: Vector2.zero(),
            color: const Color.fromARGB(255, 22, 170, 61)
          ),
        ].map(
          (e) => TextComponent(
            text: 'Has Ganado!',
            anchor: Anchor.center,
            position: e.position,
            textRenderer: TextPaint(
              style: TextStyle(color: e.color, fontSize: 12),
            ),
          ),
        ),
      );
    }
  }

  var enemiesFullyAdded = false;

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < 2; i++) {
      await world.add(
        Enemy(
          Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 7 - 3.5),
              (_random.nextDouble() * 3)),
          aliens.getSprite(EnemyColor.randomColor.fileName),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    enemiesFullyAdded = true;
    print("enemies fully added: $enemiesFullyAdded");
  }
}
