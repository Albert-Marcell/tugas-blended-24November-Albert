import 'package:flutter/material.dart';

class ScaleSwipeScreen extends StatefulWidget {
  const ScaleSwipeScreen({super.key});

  @override
  State<ScaleSwipeScreen> createState() => _ScaleSwipeScreenState();
}

class _ScaleSwipeScreenState extends State<ScaleSwipeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Transformasi pinch (dua jari)
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _currentRotation = 0.0;
  double _baseRotation = 0.0;

  // TUGAS LANJUT: posisi geser kartu (satu jari)
  double _dragX = 0.0;
  static const double _swipeThreshold = 120.0; // ambang batas ±120 px

  int _approvedCount = 0;
  int _skippedCount = 0;

  late final AnimationController _animController;
  Animation<double>? _dragAnimation;

  final List<Map<String, dynamic>> _galleryItems = const [
    {
      'title': 'Eksplorasi Pegunungan',
      'tag': 'KARTU 1 / 3',
      'desc': 'Geser kanan untuk SETUJU, geser kiri untuk LEWATI. Dua jari untuk zoom & putar.',
      'icon': Icons.terrain,
      'color': Color(0xFF0F766E),
    },
    {
      'title': 'Arsitektur Modern',
      'tag': 'KARTU 2 / 3',
      'desc': 'Geser kartu melewati batas ±120 piksel agar kartu terlempar keluar.',
      'icon': Icons.location_city,
      'color': Color(0xFF1D4ED8),
    },
    {
      'title': 'Observasi Antariksa',
      'tag': 'KARTU 3 / 3',
      'desc': 'Tekan tombol Reset untuk mengembalikan skala ke 1.0x.',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF6D28D9),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() => _dragX = _dragAnimation?.value ?? _dragX);
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _resetTransform() {
    setState(() {
      _currentScale = 1.0;
      _baseScale = 1.0;
      _currentRotation = 0.0;
      _baseRotation = 0.0;
    });
  }

  // Animasikan _dragX ke nilai target
  Future<void> _animateDragTo(double target, Curve curve) {
    _dragAnimation = Tween<double>(begin: _dragX, end: target)
        .animate(CurvedAnimation(parent: _animController, curve: curve));
    return _animController.forward(from: 0);
  }

  // Lempar kartu keluar layar lalu muat kartu berikutnya
  Future<void> _flyOut(bool approved) async {
    final screenWidth = MediaQuery.of(context).size.width;
    await _animateDragTo(
      approved ? screenWidth * 1.5 : -screenWidth * 1.5,
      Curves.easeIn,
    );
    if (!mounted) return;
    setState(() {
      if (approved) {
        _approvedCount++;
      } else {
        _skippedCount++;
      }
      _currentIndex = (_currentIndex + 1) % _galleryItems.length;
      _dragX = 0.0;
    });
    _resetTransform();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved ? 'Kartu disetujui ✔' : 'Kartu dilewati ✖'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _galleryItems[_currentIndex];
    final Color cardColor = item['color'] as Color;

    // Opasitas label berdasarkan jarak geser
    final labelOpacity = (_dragX.abs() / _swipeThreshold).clamp(0.0, 1.0);
    // Kemiringan kecil saat digeser (efek ala Tinder)
    final dragTilt = _dragX / 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen 4: Pinch & Swipe Cards'),
        actions: [
          IconButton(
            tooltip: 'Kembali ke Beranda',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Indikator Skala & Rotasi Real-Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Skala: ${_currentScale.toStringAsFixed(2)}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rotasi: ${(_currentRotation * 57.2958).toStringAsFixed(0)}°',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _resetTransform,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            // Area Kartu: satu jari = geser, dua jari = zoom & putar
            Expanded(
              child: Center(
                child: GestureDetector(
                  onScaleStart: (details) {
                    if (_animController.isAnimating) return;
                    _baseScale = _currentScale;
                    _baseRotation = _currentRotation;
                  },
                  onScaleUpdate: (details) {
                    if (_animController.isAnimating) return;
                    setState(() {
                      if (details.pointerCount >= 2) {
                        // Dua jari: pinch-to-zoom & rotasi
                        _currentScale = (_baseScale * details.scale).clamp(0.6, 2.2);
                        _currentRotation = _baseRotation + details.rotation;
                      } else if (_currentScale == 1.0) {
                        // Satu jari (hanya saat skala normal): geser horizontal
                        _dragX += details.focalPointDelta.dx;
                      }
                    });
                  },
                  onScaleEnd: (details) {
                    if (_animController.isAnimating) return;
                    if (_dragX > _swipeThreshold) {
                      _flyOut(true); // geser kanan → SETUJU
                    } else if (_dragX < -_swipeThreshold) {
                      _flyOut(false); // geser kiri → LEWATI
                    } else if (_dragX != 0) {
                      _animateDragTo(0.0, Curves.easeOutBack); // kembali ke tengah
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(_dragX, 0),
                    child: Transform.rotate(
                      angle: _currentRotation + dragTilt,
                      child: Transform.scale(
                        scale: _currentScale,
                        child: Stack(
                          children: [
                            _buildCard(item, cardColor),
                            // Label SETUJU (geser kanan)
                            if (_dragX > 0)
                              Positioned(
                                top: 24,
                                left: 20,
                                child: Opacity(
                                  opacity: labelOpacity,
                                  child: _buildStamp('SETUJU', const Color(0xFF22C55E), -0.25),
                                ),
                              ),
                            // Label LEWATI (geser kiri)
                            if (_dragX < 0)
                              Positioned(
                                top: 24,
                                right: 20,
                                child: Opacity(
                                  opacity: labelOpacity,
                                  child: _buildStamp('LEWATI', const Color(0xFFEF4444), 0.25),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Indikator kartu & statistik keputusan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_galleryItems.length, (idx) {
                      final isActive = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1B365D)
                              : const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disetujui: $_approvedCount   |   Dilewati: $_skippedCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B365D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, Color cardColor) {
    return Container(
      width: 270,
      height: 310,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withAlpha(95),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item['tag'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Icon(item['icon'] as IconData, size: 76, color: Colors.white),
          const SizedBox(height: 18),
          Text(
            item['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['desc'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStamp(String text, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 3),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
