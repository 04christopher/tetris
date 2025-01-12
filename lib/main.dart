import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'line_complete_animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

void main() {
  runApp(MaterialApp(
    home: TetrisGame(),
    debugShowCheckedModeBanner: false,
  ));
}

// Game board dimensions
const int boardWidth = 10;
const int boardHeight = 20;
const double blockSize = 30.0; 
const double gameScale = 1.2; 

// Tetromino shapes
final List<List<List<int>>> tetrominoShapes = [
  // I-shape
  [
    [1, 1, 1, 1]
  ],
  // J-shape
  [
    [1, 0, 0],
    [1, 1, 1],
  ],
  // L-shape
  [
    [0, 0, 1],
    [1, 1, 1],
  ],
  // O-shape
  [
    [1, 1],
    [1, 1],
  ],
  // S-shape
  [
    [0, 1, 1],
    [1, 1, 0],
  ],
  // T-shape
  [
    [0, 1, 0],
    [1, 1, 1],
  ],
  // Z-shape
  [
    [1, 1, 0],
    [0, 1, 1],
  ],
];

// Tetromino colors
const List<Color> tetrominoColors = [
  // Color.fromARGB(255, 94, 77, 244),
  // Colors.blue,
  // Colors.orange,
  // Color.fromARGB(255, 220, 202, 37),
  // Color.fromARGB(255, 45, 131, 48),
  // Colors.purple,
  // Colors.red,
  // alternate colors
  Color.fromARGB(255, 244, 77, 169),
  Color.fromARGB(255, 217, 7, 232),
  Color.fromARGB(255, 238, 160, 184),
  Color.fromARGB(255, 196, 3, 255),
  Color.fromARGB(255, 218, 31, 105),
  Color.fromARGB(255, 167, 120, 213),
  Color.fromARGB(255, 100, 2, 153),
];

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  _TetrisGameState createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  late List<List<int>> board;
  late List<List<int>> currentShape;
  late int currentTetrominoType;
  late int currentTetrominoX;
  late int currentTetrominoY;
  late int score;
  Timer? timer;
  bool _isAnimating = false;
  int _completedLines = 0;

  final FocusNode _focusNode = FocusNode();
  Timer? _keyRepeatTimer;
  Timer? _gameTimer;
  
  // Add variables to track key states
  bool _isLeftKeyDown = false;
  bool _isRightKeyDown = false;
  bool _isDownKeyDown = false;
  
  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  late List<List<Color>> boardColors;

  void initializeGame() {
    board = List.generate(
      boardHeight,
      (y) => List.generate(boardWidth, (x) => 0),
    );
    // Initialize board colors with a transparent color
    boardColors = List.generate(
      boardHeight,
      (y) => List.generate(boardWidth, (x) => Colors.transparent),
    );
    currentTetrominoType = 0;
    currentTetrominoX = 0;
    currentTetrominoY = 0;
    score = 0;
    spawnTetromino();
    _startGameTimer();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      moveTetrominoDown();
    });
  }

  void _startKeyRepeat(void Function() movement) {
    _keyRepeatTimer?.cancel();
    
    // Initial delay before repeat starts
    _keyRepeatTimer = Timer(const Duration(milliseconds: 170), () {
      _keyRepeatTimer?.cancel();
      // Faster repeat rate after initial delay
      _keyRepeatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        movement();
      });
    });
  }

  void _stopKeyRepeat() {
    _keyRepeatTimer?.cancel();
    _keyRepeatTimer = null;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyRepeatTimer?.cancel();
    _gameTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (!_isLeftKeyDown) {
            _isLeftKeyDown = true;
            moveTetrominoLeft();
            _startKeyRepeat(moveTetrominoLeft);
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (!_isRightKeyDown) {
            _isRightKeyDown = true;
            moveTetrominoRight();
            _startKeyRepeat(moveTetrominoRight);
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (!_isDownKeyDown) {
            _isDownKeyDown = true;
            moveTetrominoDown();
            _startKeyRepeat(moveTetrominoDown);
          }
          break;
        case LogicalKeyboardKey.arrowUp:
          rotateTetromino();
          break;
        case LogicalKeyboardKey.space:
          dropTetrominoToBottom();
          break;
        case LogicalKeyboardKey.digit9:
        _isAnimating = true;
        //   LineCompleteAnimation(
        //   linesCleared: 1,
        //   scale: gameScale,
        //   onComplete: () {
        //     setState(() {
        //       _isAnimating = false;
        //     });
        //   },
        // );
        break;
      }
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _isLeftKeyDown = false;
          if (!_isRightKeyDown && !_isDownKeyDown) {
            _stopKeyRepeat();
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          _isRightKeyDown = false;
          if (!_isLeftKeyDown && !_isDownKeyDown) {
            _stopKeyRepeat();
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          _isDownKeyDown = false;
          if (!_isLeftKeyDown && !_isRightKeyDown) {
            _stopKeyRepeat();
          }
          // Restart normal game speed when down key is released
          _startGameTimer();
          break;
        case LogicalKeyboardKey.digit9:
          LineCompleteAnimation(
          linesCleared: 1,
          scale: gameScale,
          onComplete: () {
            setState(() {
              _isAnimating = false;
            });
          },
        );
        break;
      }
    }
  }

  void dropTetrominoToBottom() {
    setState(() {
      while (!hasCollision(yOffset: 1)) {
        currentTetrominoY++;
      }
      placeTetromino();
      spawnTetromino();
    });
  }

  void spawnTetromino() {
    final random = Random();
    currentTetrominoType = random.nextInt(tetrominoShapes.length);
    
    // Deep copy the shape
    currentShape = List.generate(
      tetrominoShapes[currentTetrominoType].length,
      (i) => List.from(tetrominoShapes[currentTetrominoType][i]),
    );
    
    currentTetrominoX = boardWidth ~/ 2 - currentShape[0].length ~/ 2;
    currentTetrominoY = 0;

    if (hasCollision()) {
      timer?.cancel();
      showGameOver();
    }
  }

  void showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      board = List.generate(
        boardHeight,
        (y) => List.generate(boardWidth, (x) => 0),
      );
      boardColors = List.generate(
        boardHeight,
        (y) => List.generate(boardWidth, (x) => Colors.transparent),
      );
      score = 0;
      spawnTetromino();
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        moveTetrominoDown();
      });
    });
  }

  void rotateTetromino() {
    setState(() {
      // Create a new shape with swapped dimensions
      final int rows = currentShape.length;
      final int cols = currentShape[0].length;
      final List<List<int>> newShape = List.generate(
        cols,
        (i) => List.generate(rows, (j) => 0),
      );

      // Perform the rotation
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          newShape[j][rows - 1 - i] = currentShape[i][j];
        }
      }

      if (!hasCollision(newShape: newShape)) {
        currentShape = newShape;
      }
    });
  }

  void moveTetrominoDown() {
    setState(() {
      if (!hasCollision(yOffset: 1)) {
        currentTetrominoY++;
      } else {
        placeTetromino();
        spawnTetromino();
      }
    });
  }

  void moveTetrominoLeft() {
    setState(() {
      if (!hasCollision(xOffset: -1)) {
        currentTetrominoX--;
      }
    });
  }

  void moveTetrominoRight() {
    setState(() {
      if (!hasCollision(xOffset: 1)) {
        currentTetrominoX++;
      }
    });
  }

  bool hasCollision({
    List<List<int>>? newShape,
    int xOffset = 0,
    int yOffset = 0,
  }) {
    final shape = newShape ?? currentShape;
    
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          final boardX = currentTetrominoX + x + xOffset;
          final boardY = currentTetrominoY + y + yOffset;

          if (boardX < 0 ||
              boardX >= boardWidth ||
              boardY >= boardHeight ||
              (boardY >= 0 && board[boardY][boardX] == 1)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void placeTetromino() {
    for (int y = 0; y < currentShape.length; y++) {
      for (int x = 0; x < currentShape[y].length; x++) {
        if (currentShape[y][x] == 1) {
          final boardX = currentTetrominoX + x;
          final boardY = currentTetrominoY + y;
          if (boardY >= 0 && boardY < boardHeight && boardX >= 0 && boardX < boardWidth) {
            board[boardY][boardX] = 1;
            // Store a dimmed version of the tetromino color
            boardColors[boardY][boardX] = tetrominoColors[currentTetrominoType].withOpacity(0.6);
          }
        }
      }
    }
    checkCompletedLines();
  }

void checkCompletedLines() {
  _completedLines = 0;
  List<int> linesToRemove = [];
  
  for (int y = boardHeight - 1; y >= 0; y--) {
    if (board[y].every((cell) => cell == 1)) {
      _completedLines++;
      linesToRemove.add(y);
    }
  }

  if (_completedLines > 0) {
    setState(() {
      _isAnimating = true;
      score += _completedLines * 100;
      
      // Remove completed lines
      for (int y in linesToRemove) {
        board.removeAt(y);
        boardColors.removeAt(y);
        // Add new empty line at top
        board.insert(0, List.generate(boardWidth, (x) => 0));
        boardColors.insert(0, List.generate(boardWidth, (x) => Colors.transparent));
      }
    });
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[800],
    appBar: AppBar(title: GradientText(
                    'JOSTLETRIS: The Jostle Tetris Game', 
                    style: GoogleFonts.majorMonoDisplay (
                    fontSize: 45* gameScale,),
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.purple,
                    ],
                  ),
                  ),
    body: KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Transform.scale(
                      scale: gameScale,
                      child: CustomPaint(
                        size: Size(
                          boardWidth * blockSize,
                          boardHeight * blockSize,
                        ),
                        painter: BoardPainter(
                          board,
                          currentShape,
                          currentTetrominoX,
                          currentTetrominoY,
                          tetrominoColors[currentTetrominoType],
                          boardColors
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isAnimating)
                  LineCompleteAnimation(
                  linesCleared: _completedLines,
                  scale: gameScale,
                  onComplete: () {
                    setState(() {
                      _isAnimating = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GradientText(
                    'Score: $score', 
                    style: GoogleFonts.majorMonoDisplay (
                    fontSize: 45 * gameScale,),
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.purple,
                    ],
                  ),
                  SizedBox(height: 10 * gameScale),
                  GradientText(
                    'Controls:\n'
                    '← → : Move left/right\n'
                    '↑ : Rotate\n'
                    '↓ : Move down \n'
                    'Space : Hard drop',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.majorMonoDisplay (
                    fontSize: 35 * gameScale),
                    colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.purple,
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ),
  );
}
}

class BoardPainter extends CustomPainter {
  final List<List<int>> board;
  final List<List<Color>> boardColors;
  final List<List<int>> currentShape;
  final int currentTetrominoX;
  final int currentTetrominoY;
  final Color currentColor;

  BoardPainter(
    this.board,
    this.currentShape,
    this.currentTetrominoX,
    this.currentTetrominoY,
    this.currentColor,
    this.boardColors,
  );

  @override
  void paint(Canvas canvas, Size size) {
    
    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.grey[800]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical grid lines
    for (int x = 0; x <= boardWidth; x++) {
      canvas.drawLine(
        Offset(x * blockSize, 0),
        Offset(x * blockSize, boardHeight * blockSize),
        gridPaint,
      );
    }

    // Draw horizontal grid lines
    for (int y = 0; y <= boardHeight; y++) {
      canvas.drawLine(
        Offset(0, y * blockSize),
        Offset(boardWidth * blockSize, y * blockSize),
        gridPaint,
      );
    }

    // Draw placed blocks with their stored colors
    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        if (board[y][x] == 1) {
          final rect = Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize);
          final paint = Paint()
            ..color = boardColors[y][x]
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, paint);
        }
      }
    }

    // Draw current tetromino
    final tetrominoPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;
      
    for (int y = 0; y < currentShape.length; y++) {
      for (int x = 0; x < currentShape[y].length; x++) {
        if (currentShape[y][x] == 1) {
          final rect = Rect.fromLTWH(
            (currentTetrominoX + x) * blockSize,
            (currentTetrominoY + y) * blockSize,
            blockSize,
            blockSize,
          );
          canvas.drawRect(rect, tetrominoPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true;
  }
}