import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
runApp(const ClickTargetGame());
}

class ClickTargetGame extends StatelessWidget {
const ClickTargetGame({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Click The Target',
theme: ThemeData(useMaterial3: true),
home: const GameScreen(),
);
}
}

class Particle {
double x;
double y;
double dx;
double dy;
double size;
double life;

Particle({
required this.x,
required this.y,
required this.dx,
required this.dy,
required this.size,
required this.life,
});
}

class _ParticlePainter extends CustomPainter {
final List<Particle> particles;

_ParticlePainter(this.particles);

@override
void paint(Canvas canvas, Size size) {
final paint = Paint();

for (final p in particles) {
  paint.color = Colors.yellow.withOpacity(p.life.clamp(0.0, 1.0));
  canvas.drawCircle(
    Offset(p.x, p.y),
    p.size,
    paint,
  );
}

}

@override
bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
return true;
}
}

class GameScreen extends StatefulWidget {
const GameScreen({super.key});

@override
State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
with SingleTickerProviderStateMixin {
final Random random = Random();
final AudioPlayer audioPlayer = AudioPlayer();

Timer? timer;
Timer? comboTimer;
Timer? speedTimer;
Timer? particleTimer;

late AnimationController animationController;

int score = 0;
int highScore = 0;
int timeLeft = 30;
int combo = 0;
int lives = 3;
int coins = 0;

bool playing = false;
bool gameOver = false;
bool showEffect = false;
bool speedPower = false;
bool bonusTarget = false;
bool mysteryBox = false;

double targetX = 100;
double targetY = 180;
double targetSize = 80;

Color targetColor = Colors.red;

String funnyText = '';

final List<Color> colors = [
Colors.red,
Colors.blue,
Colors.green,
Colors.orange,
Colors.purple,
Colors.pink,
Colors.cyan,
Colors.yellow,
Colors.teal,
Colors.indigo,
];

final List<String> funnyWords = [
'PAKDA! 😂',
'BOOM! 💥',
'NICE! 🔥',
'WAH! 🤩',
'ZABARDAST! ⭐',
'KYA AIM HAI! 🎯',
];

final List<String> targetSounds = [
'TARGET 2.mp3',
'TARGET 3.mp3',
];

final String gameOverSound = 'GAME TARDET VOICE.mp3';

List<Particle> particles = [];

@override
void initState() {
super.initState();

animationController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 8),
)..repeat();

loadHighScore();
loadCoins();

}

Future<void> loadHighScore() async {
final prefs = await SharedPreferences.getInstance();
final savedScore = prefs.getInt('highScore') ?? 0;

if (!mounted) return;

setState(() {
  highScore = savedScore;
});

}

Future<void> saveHighScore() async {
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('highScore', highScore);
}

Future<void> loadCoins() async {
final prefs = await SharedPreferences.getInstance();
final savedCoins = prefs.getInt('coins') ?? 0;

if (!mounted) return;

setState(() {
  coins = savedCoins;
});

}

Future<void> saveCoins() async {
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('coins', coins);
}

void startGame() {
timer?.cancel();
comboTimer?.cancel();
speedTimer?.cancel();
particleTimer?.cancel();

setState(() {
  score = 0;
  timeLeft = 30;
  combo = 0;
  lives = 3;

  playing = true;
  gameOver = false;
  showEffect = false;
  speedPower = false;
  bonusTarget = false;
  mysteryBox = false;
  funnyText = '';
  particles.clear();

  moveTarget();
});

timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  if (!mounted) {
    timer.cancel();
    return;
  }

  if (timeLeft <= 1) {
    timer.cancel();
    comboTimer?.cancel();
    speedTimer?.cancel();

    playGameOverSound();

    if (score > highScore) {
      highScore = score;
      saveHighScore();
    }

    setState(() {
      timeLeft = 0;
      combo = 0;
      speedPower = false;
      bonusTarget = false;
      mysteryBox = false;
      playing = false;
      gameOver = true;
      funnyText = 'TIME UP! ⏰😂';
    });
  } else {
    setState(() {
      timeLeft--;
    });
  }
});

}

void moveTarget() {
targetX = 30 + random.nextDouble() * 280;
targetY = 160 + random.nextDouble() * 300;

if (speedPower) {
  targetSize = 45 + random.nextDouble() * 45;
} else if (bonusTarget) {
  targetSize = 60 + random.nextDouble() * 30;
} else if (mysteryBox) {
  targetSize = 65 + random.nextDouble() * 25;
} else {
  targetSize = 55 + random.nextDouble() * 50;
}

targetColor = colors[random.nextInt(colors.length)];

}

Future<void> playTargetSound() async {
final sound = targetSounds[random.nextInt(targetSounds.length)];

try {
  await audioPlayer.stop();
  await audioPlayer.play(
    AssetSource('sounds/$sound'),
  );
} catch (e) {
  debugPrint('Target sound error: $e');
}

}

Future<void> playGameOverSound() async {
try {
await audioPlayer.stop();
await audioPlayer.play(
AssetSource('sounds/$gameOverSound'),
);
} catch (e) {
debugPrint('Game Over sound error: $e');
}
}

void createHitAnimation() {
particles.clear();

for (int i = 0; i < 30; i++) {
  final angle = random.nextDouble() * 2 * pi;
  final speed = 2.0 + random.nextDouble() * 5;

  particles.add(
    Particle(
      x: targetX + targetSize / 2,
      y: targetY + targetSize / 2,
      dx: cos(angle) * speed,
      dy: sin(angle) * speed,
      size: 3 + random.nextDouble() * 7,
      life: 1,
    ),
  );
}

particleTimer?.cancel();

particleTimer = Timer.periodic(
  const Duration(milliseconds: 40),
  (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (!playing && particles.isEmpty) {
      timer.cancel();
      return;
    }

    for (final p in particles) {
      p.x += p.dx;
      p.y += p.dy;
      p.dy += 0.15;
      p.life -= 0.035;
    }

    particles.removeWhere((p) => p.life <= 0);

    setState(() {});
  },
);

}

void activateSpeedPower() {
if (!playing || speedPower) return;

speedTimer?.cancel();

setState(() {
  speedPower = true;
  funnyText = '⚡ SPEED POWER! ⚡';
  showEffect = true;
  moveTarget();
});

speedTimer = Timer(const Duration(seconds: 5), () {
  if (!mounted) return;

  if (playing) {
    setState(() {
      speedPower = false;
      funnyText = '';
      showEffect = false;
      moveTarget();
    });
  }
});

}

void activateBonusTarget() {
if (!playing || bonusTarget || mysteryBox) return;

setState(() {
  bonusTarget = true;
  funnyText = '💎 BONUS TARGET! +5 💎';
  showEffect = true;
  moveTarget();
});

}

void activateMysteryBox() {
if (!playing || mysteryBox) return;

setState(() {
  mysteryBox = true;
  funnyText = '🎁 MYSTERY BOX! 🎁';
  showEffect = true;
  moveTarget();
});

}

void openMysteryBox() {
final rewardType = random.nextInt(4);

if (rewardType == 0) {
  score += 10;
  funnyText = '🎁 +10 SCORE! ⭐';
} else if (rewardType == 1) {
  score += 20;
  funnyText = '🎁 JACKPOT! +20 ⭐';
} else if (rewardType == 2) {
  coins += 10;
  funnyText = '🎁 +10 COINS! 🪙';
  saveCoins();
} else {
  lives = min(3, lives + 1);
  funnyText = '🎁 +1 LIFE! ❤️';
}

if (score > highScore) {
  highScore = score;
  saveHighScore();
}

mysteryBox = false;
showEffect = true;

createHitAnimation();

}

void startComboTimer() {
comboTimer?.cancel();

comboTimer = Timer(const Duration(seconds: 2), () {
  if (!mounted) return;

  if (playing) {
    setState(() {
      combo = 0;
    });
  }
});

}

Future<void> clickTarget() async {
if (!playing) return;

await playTargetSound();

if (!mounted || !playing) return;

comboTimer?.cancel();

final bool wasBonus = bonusTarget;
final bool wasMystery = mysteryBox;

if (wasMystery) {
  setState(() {
    combo++;
    openMysteryBox();
  });
} else {
  setState(() {
    combo++;

    if (wasBonus) {
      final reward = 5 + combo;
      score += reward;
      coins += 2;
      funnyText = '💎 BONUS! +$reward 💎';
      bonusTarget = false;
    } else {
      score += combo;
      coins += 1;
      funnyText = funnyWords[random.nextInt(funnyWords.length)];
    }

    if (score > highScore) {
      highScore = score;
      saveHighScore();
    }

    showEffect = true;

    createHitAnimation();
    moveTarget();
  });

  saveCoins();
}

final int powerChance = random.nextInt(8);

if (powerChance == 0 && !speedPower) {
  activateSpeedPower();
} else if (powerChance == 1 && !bonusTarget && !mysteryBox) {
  activateBonusTarget();
} else if (powerChance == 2 && !bonusTarget && !mysteryBox) {
  activateMysteryBox();
}

startComboTimer();

Future.delayed(const Duration(milliseconds: 800), () {
  if (!mounted) return;

  if (playing) {
    setState(() {
      showEffect = false;
    });
  }
});

}

Future<void> missedTarget() async {
if (!playing) return;

comboTimer?.cancel();

await playGameOverSound();

if (!mounted) return;

setState(() {
  lives--;
  combo = 0;
  funnyText = 'MISS! 😅';
  showEffect = true;
  bonusTarget = false;
  mysteryBox = false;
});

if (lives <= 0) {
  timer?.cancel();
  speedTimer?.cancel();

  if (score > highScore) {
    highScore = score;
    saveHighScore();
  }

  setState(() {
    playing = false;
    gameOver = true;
    speedPower = false;
    funnyText = 'MISS! GAME OVER! 💥';
  });
} else {
  moveTarget();

  Future.delayed(const Duration(milliseconds: 800), () {
    if (!mounted) return;

    if (playing) {
      setState(() {
        showEffect = false;
        funnyText = '';
      });
    }
  });
}

}

@override
void dispose() {
timer?.cancel();
comboTimer?.cancel();
speedTimer?.cancel();
particleTimer?.cancel();
animationController.dispose();
audioPlayer.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: AnimatedBuilder(
animation: animationController,
builder: (context, child) {
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: missedTarget,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A00E0),
                    Color(0xFF8E2DE2),
                    Color(0xFFFF0080),
                    Color(0xFFFF8C00),
                    Color(0xFF00C9FF),
                  ],
                ),
              ),
            ),

            ...List.generate(35, (index) {
              final x = ((index * 83) % 100) / 100;
              final y = ((index * 47) % 100) / 100;
              final size = 15.0 + (index % 5) * 10;
              final color = colors[index % colors.length];

              return Positioned(
                left: screenWidth * x,
                top: screenHeight * y,
                child: Transform.translate(
                  offset: Offset(
                    sin(
                          animationController.value * 2 * pi + index,
                        ) *
                        12,
                    cos(
                          animationController.value * 2 * pi + index,
                        ) *
                        12,
                  ),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.65),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            ...List.generate(20, (index) {
              final x = ((index * 137) % 100) / 100;
              final y = ((index * 71) % 100) / 100;

              return Positioned(
                left: screenWidth * x,
                top: screenHeight * y,
                child: Transform.rotate(
                  angle: animationController.value * 2 * pi,
                  child: Text(
                    index % 2 == 0 ? '⭐' : '✨',
                    style: TextStyle(
                      fontSize: 18 + (index % 3) * 8,
                    ),
                  ),
                ),
              );
            }),

            const Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '🎯 CLICK THE TARGET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 75,
              left: 20,
              child: Text(
                '⭐ Score: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Positioned(
              top: 75,
              right: 20,
              child: Text(
                '⏱️ Time: $timeLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Positioned(
              top: 110,
              left: 20,
              child: Text(
                '❤️ Lives: $lives',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Positioned(
              top: 110,
              right: 20,
              child: Text(
                '🏆 Best: $highScore',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Positioned(
              top: 145,
              left: 20,
              child: Text(
                '🪙 Coins: $coins',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),

            if (speedPower)
              const Positioned(
                top: 145,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '⚡ SPEED POWER ACTIVE ⚡',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (bonusTarget)
              const Positioned(
                top: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '💎 BONUS TARGET = +5 💎',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (mysteryBox)
              const Positioned(
                top: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '🎁 MYSTERY BOX! OPEN IT! 🎁',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (playing &&
                combo > 1 &&
                !speedPower &&
                !bonusTarget &&
                !mysteryBox)
              Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '🔥 COMBO ×$combo',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (playing)
              Positioned(
                left: targetX,
                top: targetY,
                child: GestureDetector(
                  onTap: clickTarget,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: targetSize,
                    height: targetSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mysteryBox
                          ? Colors.deepOrange
                          : bonusTarget
                              ? Colors.amber
                              : targetColor,
                      border: Border.all(
                        color: Colors.white,
                        width: mysteryBox || bonusTarget ? 7 : 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: mysteryBox
                              ? Colors.orange
                              : bonusTarget
                                  ? Colors.yellow
                                  : targetColor.withOpacity(0.9),
                          blurRadius: mysteryBox || bonusTarget
                              ? 45
                              : speedPower
                                  ? 40
                                  : 30,
                          spreadRadius: mysteryBox || bonusTarget
                              ? 18
                              : speedPower
                                  ? 15
                                  : 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        mysteryBox
                            ? '🎁'
                            : bonusTarget
                                ? '💎'
                                : speedPower
                                    ? '⚡'
                                    : '🎯',
                        style: TextStyle(
                          fontSize: mysteryBox || bonusTarget
                              ? 38
                              : speedPower
                                  ? 42
                                  : 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            IgnorePointer(
              child: CustomPaint(
                size: Size(screenWidth, screenHeight),
                painter: _ParticlePainter(particles),
              ),
            ),

            if (showEffect && playing)
              Center(
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        funnyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mysteryBox
                            ? '🎁 TAP THE BOX! 🎁'
                            : bonusTarget
                                ? '💎 BONUS REWARD! 💎'
                                : speedPower
                                    ? '⚡ FAST FAST FAST! ⚡'
                                    : combo > 1
                                        ? '+$combo ⭐ 🔥'
                                        : '+1 ⭐ ✨ ⭐',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!playing && !gameOver)
              Center(
                child: ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 45,
                      vertical: 20,
                    ),
                  ),
                  child: const Text(
                    '🎮 START GAME',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            if (gameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        funnyText == 'MISS! GAME OVER! 💥'
                            ? '💥 MISS! GAME OVER!'
                            : '🎉 GAME OVER!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        funnyText == 'TIME UP! ⏰😂'
                            ? '⏰ TIME UP!'
                            : '🏆 Final Score: $score',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🏆 High Score: $highScore',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🪙 Coins: $coins',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: startGame,
                        child: const Text(
                          '🔄 RESTART',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  ),
);

}
}