import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClickTargetGame());
}

class ClickTargetGame extends StatelessWidget {
  const ClickTargetGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Click The Target',
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class Particle {
  double x;
  double y;
  double dx;
  double dy;
  double life;
  final String emoji;

  Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.life,
    required this.emoji,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random random = Random();
  final AudioPlayer audioPlayer = AudioPlayer();

  Timer? gameTimer;
  Timer? introTimer;
  Timer? comboTimer;
  Timer? speedTimer;
  Timer? effectTimer;

  int score = 0;
  int highScore = 0;
  int survivalSeconds = 0;
  int combo = 0;
  int lives = 3;
  int coins = 0;
  int roundCoins = 0;

  bool showIntro = true;
  bool playing = false;
  bool gameOver = false;
  bool showShop = false;

  bool showEffect = false;
  bool speedPower = false;
  bool bonusTarget = false;
  bool mysteryBox = false;

  double targetX = 100;
  double targetY = 250;
  double targetSize = 110;

  String funnyText = '';

  int selectedSkin = 0;
  List<int> unlockedSkins = [0];

  final List<Particle> particles = [];

  final List<String> skinNames = [
    'Classic',
    'Gold',
    'Neon',
    'Fire',
    'Ghost',
    'Rainbow',
    'Lightning',
    'Toxic',
    'Ice',
    'Galaxy',
  ];

  final List<String> skinIcons = [
    '🎯',
    '🟡',
    '🟢',
    '🔥',
    '👻',
    '🌈',
    '⚡',
    '☠️',
    '🧊',
    '🌌',
  ];

  final List<int> skinPrices = [
    0,
    75,
    150,
    225,
    300,
    375,
    450,
    545,
    658,
    799,
  ];

  final List<Color> skinColors = [
    Colors.red,
    Colors.amber,
    Colors.greenAccent,
    Colors.deepOrange,
    Colors.white,
    Colors.purpleAccent,
    Colors.yellowAccent,
    Colors.limeAccent,
    Colors.cyanAccent,
    Colors.deepPurpleAccent,
  ];

  @override
  void initState() {
    super.initState();

    loadSavedData();

    introTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted) return;

        setState(() {
          showIntro = false;
        });
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    introTimer?.cancel();
    comboTimer?.cancel();
    speedTimer?.cancel();
    effectTimer?.cancel();

    audioPlayer.dispose();

    super.dispose();
  }

  // =========================
  // SAVE / LOAD
  // =========================

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final savedSkins = prefs.getStringList('unlockedSkins');

    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
      coins = prefs.getInt('coins') ?? 0;

      selectedSkin = prefs.getInt('selectedSkin') ?? 0;

      if (savedSkins != null && savedSkins.isNotEmpty) {
        unlockedSkins = savedSkins
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .where((i) => i >= 0 && i < skinNames.length)
            .toSet()
            .toList();

        if (!unlockedSkins.contains(0)) {
          unlockedSkins.insert(0, 0);
        }
      }

      if (selectedSkin < 0 ||
          selectedSkin >= skinNames.length ||
          !unlockedSkins.contains(selectedSkin)) {
        selectedSkin = 0;
      }
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('highScore', highScore);
    await prefs.setInt('coins', coins);
    await prefs.setInt('selectedSkin', selectedSkin);

    await prefs.setStringList(
      'unlockedSkins',
      unlockedSkins.map((e) => e.toString()).toList(),
    );
  }

  // =========================
  // SOUND
  // =========================

  Future<void> playTargetSound() async {
    final sounds = [
      'sounds/GAME TARDET VOICE.mp3',
      'sounds/TARGET 2.mp3',
      'sounds/TARGET 3.mp3',
    ];

    final selectedSound =
        sounds[random.nextInt(sounds.length)];

    try {
      await audioPlayer.stop();

      await audioPlayer.play(
        AssetSource(selectedSound),
      );
    } catch (_) {}
  }

  Future<void> playGameOverSound() async {
    try {
      await audioPlayer.stop();

      await audioPlayer.play(
        AssetSource('sounds/GAME TARDET VOICE.mp3'),
      );
    } catch (_) {}
  }

  // =========================
  // TIME
  // =========================

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  // =========================
  // TARGET SIZE
  // =========================

  double getTargetSize() {
    if (score >= 500) {
      return 30;
    }

    if (score >= 400) {
      return 42;
    }

    if (score >= 300) {
      return 55;
    }

    if (score >= 200) {
      return 70;
    }

    if (score >= 100) {
      return 90;
    }

    return 110;
  }

  String getDifficultyText() {
    if (score >= 500) {
      return '💀 GOD LEVEL 💀';
    }

    if (score >= 400) {
      return '🔥 VERY HARD';
    }

    if (score >= 300) {
      return '⚡ HARD';
    }

    if (score >= 200) {
      return '😈 DIFFICULT';
    }

    if (score >= 100) {
      return '🔥 GETTING HARD';
    }

    return '😊 EASY';
  }

  // =========================
  // START GAME
  // =========================

  void startGame() {
    gameTimer?.cancel();
    comboTimer?.cancel();
    speedTimer?.cancel();
    effectTimer?.cancel();

    setState(() {
      score = 0;
      survivalSeconds = 0;
      combo = 0;
      lives = 3;
      roundCoins = 0;

      playing = true;
      gameOver = false;
      showShop = false;

      showEffect = false;
      speedPower = false;
      bonusTarget = false;
      mysteryBox = false;

      funnyText = '';

      targetSize = 110;

      moveTarget();
    });

    gameTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || !playing) return;

        setState(() {
          survivalSeconds++;
        });
      },
    );
  }

  // =========================
  // MOVE TARGET
  // =========================

  void moveTarget() {
    targetSize = getTargetSize();

    final screenWidth =
        MediaQuery.of(context).size.width;

    final screenHeight =
        MediaQuery.of(context).size.height;

    final maxX =
        max(10.0, screenWidth - targetSize - 20);

    final usableHeight =
        max(100.0, screenHeight - 210);

    final maxY =
        max(130.0, usableHeight);

    targetX =
        10 + random.nextDouble() * maxX;

    targetY =
        135 +
        random.nextDouble() *
            max(50.0, maxY - 135);
  }

  // =========================
  // PARTICLES
  // =========================

  void createParticles() {
    particles.clear();

    const emojis = [
      '✨',
      '⭐',
      '💥',
      '🎉',
      '🔥',
      '💫',
    ];

    for (int i = 0; i < 15; i++) {
      particles.add(
        Particle(
          x: targetX + targetSize / 2,
          y: targetY + targetSize / 2,
          dx: (random.nextDouble() - 0.5) * 8,
          dy: (random.nextDouble() - 0.5) * 8,
          life: 1,
          emoji:
              emojis[random.nextInt(emojis.length)],
        ),
      );
    }

    setState(() {
      showEffect = true;
    });

    effectTimer?.cancel();

    effectTimer = Timer(
      const Duration(milliseconds: 400),
      () {
        if (!mounted) return;

        setState(() {
          particles.clear();
          showEffect = false;
        });
      },
    );
  }

  // =========================
  // COMBO
  // =========================

  void startComboTimer() {
    comboTimer?.cancel();

    comboTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted || !playing) return;

        setState(() {
          combo = 0;
        });
      },
    );
  }

  // =========================
  // SPEED POWER
  // =========================

  void activateSpeedPower() {
    speedTimer?.cancel();

    setState(() {
      speedPower = true;
      funnyText = '⚡ SPEED POWER! ⚡';
    });

    speedTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted) return;

        setState(() {
          speedPower = false;
        });
      },
    );
  }

  // =========================
  // TARGET HIT
  // =========================

  void hitTarget() {
    if (!playing) return;

    playTargetSound();
    createParticles();

    setState(() {
      combo++;

      if (combo > 10) {
        combo = 10;
      }

      startComboTimer();

      final points = combo;

      score += points;

      coins++;
      roundCoins++;

      if (score > highScore) {
        highScore = score;
      }

      funnyText = '+$points POINTS 🔥';

      bonusTarget = false;
      mysteryBox = false;

      final chance = random.nextInt(100);

      if (chance < 8) {
        activateSpeedPower();
      } else if (chance < 14) {
        bonusTarget = true;
        funnyText = '💎 BONUS TARGET! 💎';
      } else if (chance < 18) {
        mysteryBox = true;
        funnyText = '🎁 MYSTERY BOX! 🎁';
      }

      targetSize = getTargetSize();

      moveTarget();
    });

    saveData();
  }

  // =========================
  // BONUS TARGET
  // =========================

  void hitBonusTarget() {
    if (!playing) return;

    playTargetSound();
    createParticles();

    setState(() {
      final bonusPoints = 5 + combo;

      score += bonusPoints;

      coins += 2;
      roundCoins += 2;

      bonusTarget = false;

      funnyText =
          '💎 BONUS +$bonusPoints SCORE! 💎';

      if (score > highScore) {
        highScore = score;
      }

      moveTarget();
    });

    saveData();
  }

  // =========================
  // MYSTERY BOX
  // =========================

  void hitMysteryBox() {
    if (!playing) return;

    playTargetSound();
    createParticles();

    final reward = random.nextInt(4);

    setState(() {
      mysteryBox = false;

      if (reward == 0) {
        score += 10;
        funnyText = '🎁 +10 SCORE!';
      } else if (reward == 1) {
        score += 20;
        funnyText = '🎁 +20 SCORE!';
      } else if (reward == 2) {
        coins += 10;
        roundCoins += 10;
        funnyText = '🎁 +10 COINS! 🪙';
      } else {
        if (lives < 3) {
          lives++;
          funnyText = '🎁 +1 LIFE! ❤️';
        } else {
          coins += 5;
          roundCoins += 5;
          funnyText = '🎁 +5 COINS! 🪙';
        }
      }

      if (score > highScore) {
        highScore = score;
      }

      moveTarget();
    });

    saveData();
  }

  // =========================
  // MISS
  // =========================

  void missTarget() {
    if (!playing) return;

    setState(() {
      lives--;

      combo = 0;

      comboTimer?.cancel();

      speedPower = false;
      bonusTarget = false;
      mysteryBox = false;

      funnyText = 'MISS! 😵';
    });

    if (lives <= 0) {
      endGame();
    }
  }

  // =========================
  // GAME OVER
  // =========================

  void endGame() {
    gameTimer?.cancel();
    comboTimer?.cancel();
    speedTimer?.cancel();

    setState(() {
      playing = false;
      gameOver = true;

      speedPower = false;
      bonusTarget = false;
      mysteryBox = false;

      combo = 0;
    });

    playGameOverSound();

    saveData();
  }

  // =========================
  // SHOP
  // =========================

  void buyOrEquipSkin(int index) {
    if (index < 0 ||
        index >= skinNames.length) {
      return;
    }

    final unlocked =
        unlockedSkins.contains(index);

    if (unlocked) {
      setState(() {
        selectedSkin = index;

        funnyText =
            '${skinNames[index]} EQUIPPED! '
            '${skinIcons[index]}';
      });

      saveData();

      return;
    }

    final price = skinPrices[index];

    if (coins < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Coins kam hain! 🪙'),
        ),
      );

      return;
    }

    setState(() {
      coins -= price;

      unlockedSkins.add(index);

      selectedSkin = index;

      funnyText = 'SKIN UNLOCKED! 🎉';
    });

    saveData();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${skinNames[index]} skin unlock ho gayi! 🎉',
        ),
      ),
    );
  }

  // =========================
  // TARGET
  // =========================

  Widget buildTarget() {
    Color targetColor;
    String targetIcon;
    VoidCallback targetAction;

    if (bonusTarget) {
      targetColor = Colors.amber;
      targetIcon = '💎';
      targetAction = hitBonusTarget;
    } else if (mysteryBox) {
      targetColor = Colors.deepOrange;
      targetIcon = '🎁';
      targetAction = hitMysteryBox;
    } else {
      targetColor = skinColors[selectedSkin];
      targetIcon = skinIcons[selectedSkin];
      targetAction = hitTarget;
    }

    return Positioned(
      left: targetX,
      top: targetY,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: targetAction,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 120),
          width: targetSize,
          height: targetSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: targetColor,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    targetColor.withOpacity(0.75),
                blurRadius:
                    speedPower ? 28 : 18,
                spreadRadius:
                    speedPower ? 7 : 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              targetIcon,
              style: TextStyle(
                fontSize: max(
                  13,
                  targetSize * 0.43,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // BACKGROUND
  // =========================

  Widget buildBackground() {
    final bool gettingHard =
        score >= 100 && score < 200;

    final bool difficult =
        score >= 200 && score < 300;

    final bool hard =
        score >= 300 && score < 400;

    final bool veryHard =
        score >= 400 && score < 500;

    final bool godLevel =
        score >= 500;

    final List<Color> backgroundColors =
        godLevel
            ? const [
                Color(0xFF050008),
                Color(0xFF300000),
                Color(0xFF090014),
              ]
            : veryHard
                ? const [
                    Color(0xFF100000),
                    Color(0xFF4A0000),
                    Color(0xFF160018),
                  ]
                : hard
                    ? const [
                        Color(0xFF241010),
                        Color(0xFF681515),
                        Color(0xFF211020),
                      ]
                    : difficult
                        ? const [
                            Color(0xFF17243A),
                            Color(0xFF34304F),
                            Color(0xFF20202D),
                          ]
                        : gettingHard
                            ? const [
                                Color(0xFFFFA751),
                                Color(0xFFFF416C),
                                Color(0xFF654EA3),
                              ]
                            : const [
                                Color(0xFFFFD86F),
                                Color(0xFFFC8EAC),
                                Color(0xFF7EE8FA),
                                Color(0xFF80FFB5),
                              ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColors,
        ),
      ),
      child: Stack(
        children: [
          if (score < 100) ...[
            const Positioned(
              left: 25,
              top: 150,
              child: Text(
                '🌈',
                style: TextStyle(fontSize: 65),
              ),
            ),
            const Positioned(
              right: 25,
              top: 210,
              child: Text(
                '⭐',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              left: 70,
              bottom: 100,
              child: Text(
                '🎉',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              right: 65,
              bottom: 150,
              child: Text(
                '🦋',
                style: TextStyle(fontSize: 50),
              ),
            ),
            const Positioned(
              right: 110,
              top: 80,
              child: Text(
                '✨',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ],

          if (gettingHard) ...[
            const Positioned(
              left: 25,
              top: 160,
              child: Text(
                '⚡',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              right: 35,
              bottom: 130,
              child: Text(
                '💥',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              left: 70,
              bottom: 90,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 45),
              ),
            ),
          ],

          if (difficult) ...[
            const Positioned(
              left: 25,
              top: 160,
              child: Text(
                '🌌',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              right: 30,
              bottom: 120,
              child: Text(
                '⚠️',
                style: TextStyle(fontSize: 50),
              ),
            ),
            const Positioned(
              left: 80,
              bottom: 80,
              child: Text(
                '👁️',
                style: TextStyle(fontSize: 45),
              ),
            ),
          ],

          if (hard) ...[
            const Positioned(
              left: 20,
              top: 150,
              child: Text(
                '☠️',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              right: 25,
              top: 230,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 60),
              ),
            ),
            const Positioned(
              left: 45,
              bottom: 100,
              child: Text(
                '⚠️',
                style: TextStyle(fontSize: 50),
              ),
            ),
            const Positioned(
              right: 70,
              bottom: 80,
              child: Text(
                '💀',
                style: TextStyle(fontSize: 55),
              ),
            ),
          ],

          if (veryHard) ...[
            const Positioned(
              left: 20,
              top: 150,
              child: Text(
                '☠️',
                style: TextStyle(fontSize: 65),
              ),
            ),
            const Positioned(
              right: 20,
              top: 220,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 70),
              ),
            ),
            const Positioned(
              left: 35,
              bottom: 100,
              child: Text(
                '💀',
                style: TextStyle(fontSize: 65),
              ),
            ),
            const Positioned(
              right: 45,
              bottom: 90,
              child: Text(
                '⚠️',
                style: TextStyle(fontSize: 60),
              ),
            ),
            const Positioned(
              right: 120,
              top: 90,
              child: Text(
                '🩸',
                style: TextStyle(fontSize: 45),
              ),
            ),
          ],

          if (godLevel) ...[
            const Positioned(
              left: 15,
              top: 130,
              child: Text(
                '💀',
                style: TextStyle(fontSize: 75),
              ),
            ),
            const Positioned(
              right: 15,
              top: 190,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 80),
              ),
            ),
            const Positioned(
              left: 25,
              bottom: 90,
              child: Text(
                '☠️',
                style: TextStyle(fontSize: 75),
              ),
            ),
            const Positioned(
              right: 30,
              bottom: 100,
              child: Text(
                '🩸',
                style: TextStyle(fontSize: 65),
              ),
            ),
            const Positioned(
              left: 130,
              top: 80,
              child: Text(
                '⚠️',
                style: TextStyle(fontSize: 55),
              ),
            ),
            const Positioned(
              right: 120,
              bottom: 210,
              child: Text(
                '👹',
                style: TextStyle(fontSize: 65),
              ),
            ),
            const Positioned(
              left: 100,
              bottom: 190,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 60),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // TOP BAR
  // =========================

  Widget buildTopBar() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          10,
          10,
          0,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                infoBox(
                  '⏱️ ${formatTime(survivalSeconds)}',
                  Colors.cyanAccent,
                ),
                infoBox(
                  '🏆 $score',
                  Colors.amber,
                ),
                infoBox(
                  '🪙 $coins',
                  Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                infoBox(
                  '🎯 $score',
                  Colors.greenAccent,
                ),
                infoBox(
                  '🔥 x$combo',
                  Colors.deepOrangeAccent,
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding:
                          const EdgeInsets.only(
                        left: 2,
                      ),
                      child: Text(
                        index < lives
                            ? '❤️'
                            : '🖤',
                        style:
                            const TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              getDifficultyText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (funnyText.isNotEmpty)
              Text(
                funnyText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget infoBox(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.6),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================
  // INTRO
  // =========================

  Widget buildIntro() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF12002F),
              Color(0xFF003B46),
              Color(0xFF4B0082),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                'DISING BY TAHA ANSARI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "INSTAGRAM I'D: tahaansari_99",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '🎯',
                style: TextStyle(fontSize: 90),
              ),
              const SizedBox(height: 12),
              const Text(
                'CLICK THE TARGET',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Loading Game... 🎮',
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 25),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // MENU
  // =========================

  Widget buildMenu() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10002B),
              Color(0xFF240046),
              Color(0xFF3C096C),
              Color(0xFF0077B6),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  '🎯',
                  style: TextStyle(fontSize: 100),
                ),
                const SizedBox(height: 8),
                const Text(
                  'CLICK THE TARGET',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '👑 HIGH SCORE: $highScore',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '🪙 COINS: $coins',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 240,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: startGame,
                    child: const Text(
                      '▶ START GAME',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 240,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        showShop = true;
                      });
                    },
                    child: const Text(
                      '🛒 SHOP',
                      style: TextStyle(fontSize: 19),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // SHOP
  // =========================

  Widget buildShop() {
    return Scaffold(
      backgroundColor:
          const Color(0xFF090018),
      appBar: AppBar(
        title: const Text(
          '🛒 TARGET SHOP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 15),
            child: Center(
              child: Text(
                '🪙 $coins',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(22),
        itemCount: skinNames.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 22,
          mainAxisSpacing: 22,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final unlocked =
              unlockedSkins.contains(index);

          final selected =
              selectedSkin == index;

          return GestureDetector(
            onTap: selected
                ? null
                : () => buyOrEquipSkin(index),
            child: Card(
              color:
                  Colors.black.withOpacity(0.65),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? Colors.greenAccent
                      : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration:
                          BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            skinColors[index],
                        boxShadow: [
                          BoxShadow(
                            color:
                                skinColors[index]
                                    .withOpacity(0.7),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          skinIcons[index],
                          style:
                              const TextStyle(
                            fontSize: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      skinNames[index],
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!unlocked)
                      Text(
                        '🪙 ${skinPrices[index]}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          color: Colors.amber,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'UNLOCKED ✅',
                        style: TextStyle(
                          color:
                              Colors.greenAccent,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: IgnorePointer(
                        child:
                            ElevatedButton(
                          onPressed: null,
                          child: Text(
                            selected
                                ? 'EQUIPPED ✅'
                                : unlocked
                                    ? 'EQUIP'
                                    : 'BUY 🪙',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================
  // GAME OVER
  // =========================

  Widget buildGameOver() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF220000),
              Color(0xFF090018),
              Color(0xFF001F3F),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  '💀 GAME OVER',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 22),
                resultBox(
                  '⏱️ SURVIVED',
                  formatTime(survivalSeconds),
                  Colors.cyanAccent,
                ),
                resultBox(
                  '🎯 SCORE',
                  '$score',
                  Colors.amber,
                ),
                resultBox(
                  '🪙 COINS EARNED',
                  '+$roundCoins',
                  Colors.orangeAccent,
                ),
                resultBox(
                  '👑 HIGH SCORE',
                  '$highScore',
                  Colors.purpleAccent,
                ),
                const SizedBox(height: 18),
                if (score >= highScore &&
                    score > 0)
                  const Text(
                    '🎉 NEW HIGH SCORE! 🎉',
                    style: TextStyle(
                      fontSize: 21,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 155,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: startGame,
                        child: const Text(
                          '🔄 RESTART',
                          style:
                              TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 155,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            showShop = true;
                          });
                        },
                        child: const Text(
                          '🛒 SHOP',
                          style:
                              TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      gameOver = false;
                    });
                  },
                  child: const Text(
                    '🏠 MENU',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget resultBox(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: 330,
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.7),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // PLAYING SCREEN
  // =========================

  Widget buildPlayingScreen() {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: missTarget,
        child: Stack(
          children: [
            Positioned.fill(
              child: buildBackground(),
            ),

            buildTarget(),

            if (showEffect)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ParticlePainter(
                      particles: particles,
                    ),
                  ),
                ),
              ),

            buildTopBar(),

            if (speedPower)
              Positioned(
                top: 112,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black.withOpacity(
                          0.65,
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⚡ SPEED POWER ACTIVE ⚡',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.yellowAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              right: 15,
              bottom: 15,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showShop = true;
                    });
                  },
                  child: const Text('🛒'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // MAIN BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    if (showIntro) {
      return buildIntro();
    }

    if (showShop) {
      return Stack(
        children: [
          buildShop(),
          Positioned(
            left: 15,
            top: 45,
            child: SafeArea(
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    showShop = false;
                  });
                },
                child:
                    const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      );
    }

    if (gameOver) {
      return buildGameOver();
    }

    if (!playing) {
      return buildMenu();
    }

    return buildPlayingScreen();
  }
}

// =========================
// PARTICLE PAINTER
// =========================

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({
    required this.particles,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    for (final particle in particles) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.emoji,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          particle.x,
          particle.y,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}