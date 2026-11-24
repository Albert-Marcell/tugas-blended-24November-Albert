import 'package:flutter/material.dart';
import 'scale_swipe_screen.dart';

class DragCanvasScreen extends StatefulWidget {
  const DragCanvasScreen({super.key});

  @override
  State<DragCanvasScreen> createState() => _DragCanvasScreenState();
}

class _DragCanvasScreenState extends State<DragCanvasScreen> {
  double _posX = 40.0;
  double _posY = 40.0;
  bool _isDragging = false;
  int _score = 0;

  // TUGAS DASAR: penghitung tabrakan & flag agar sisa gerakan diabaikan
  int _hitCount = 0;
  bool _isBlocked = false;

  static const double _objectSize = 72.0;
  static const double _targetSize = 110.0;
  static const double _dangerSize = 100.0; // ukuran Zona Bahaya

  // Kembalikan roket ke titik awal & tampilkan peringatan
  void _hitDangerZone() {
    setState(() {
      _posX = 40.0;
      _posY = 40.0;
      _hitCount++;
      _isBlocked = true; // abaikan onPanUpdate sampai jari diangkat
      _isDragging = false;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Awas! Roket menabrak Zona Bahaya. Kembali ke awal.'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen 3: Drag & Pan Canvas'),
        actions: [
          IconButton(
            tooltip: 'Ke Screen 4 (Pinch & Swipe)',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScaleSwipeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bar Informasi Koordinat, Skor & Tabrakan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posisi: (${_posX.toStringAsFixed(0)}, ${_posY.toStringAsFixed(0)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Tabrakan: $_hitCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFDC2626),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B365D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Skor: $_score',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Kanvas Interaktif
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxX = constraints.maxWidth - _objectSize;
                final maxY = constraints.maxHeight - _objectSize;

                // Posisi Drop Zone di sudut kanan bawah kanvas
                final targetLeft = constraints.maxWidth - _targetSize - 24;
                final targetTop = constraints.maxHeight - _targetSize - 24;

                // TUGAS DASAR: posisi Zona Bahaya di tengah kanvas
                final dangerLeft = (constraints.maxWidth - _dangerSize) / 2;
                final dangerTop = (constraints.maxHeight - _dangerSize) / 2;
                final dangerRect = Rect.fromLTWH(
                  dangerLeft,
                  dangerTop,
                  _dangerSize,
                  _dangerSize,
                );

                return Stack(
                  children: [
                    // Panduan Latar Belakang
                    const Positioned(
                      top: 14,
                      left: 16,
                      right: 16,
                      child: Text(
                        'Seret roket ke Zona Target hijau, hindari Zona Bahaya merah!',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                    // Zona Bahaya (rintangan)
                    Positioned(
                      left: dangerLeft,
                      top: dangerTop,
                      child: Container(
                        width: _dangerSize,
                        height: _dangerSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDC2626), width: 2.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626), size: 34),
                            SizedBox(height: 4),
                            Text(
                              'ZONA BAHAYA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Zona Target (Drop Zone)
                    Positioned(
                      left: targetLeft,
                      top: targetTop,
                      child: Container(
                        width: _targetSize,
                        height: _targetSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF059669), width: 2.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag_circle, color: Color(0xFF059669), size: 34),
                            SizedBox(height: 4),
                            Text(
                              'DROP ZONE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Objek Roket yang Dapat Diseret
                    Positioned(
                      left: _posX,
                      top: _posY,
                      child: GestureDetector(
                        onPanStart: (_) {
                          setState(() {
                            _isDragging = true;
                            _isBlocked = false;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isBlocked) return;

                          final newX = (_posX + details.delta.dx).clamp(0.0, maxX).toDouble();
                          final newY = (_posY + details.delta.dy).clamp(0.0, maxY).toDouble();

                          // Cek tabrakan: area roket bersinggungan dengan Zona Bahaya?
                          final rocketRect =
                              Rect.fromLTWH(newX, newY, _objectSize, _objectSize);
                          if (rocketRect.overlaps(dangerRect)) {
                            _hitDangerZone();
                            return;
                          }

                          setState(() {
                            _posX = newX;
                            _posY = newY;
                          });
                        },
                        onPanEnd: (_) {
                          final wasBlocked = _isBlocked;
                          setState(() {
                            _isDragging = false;
                            _isBlocked = false;
                          });
                          if (wasBlocked) return;

                          // Hitung titik tengah objek roket
                          final centerX = _posX + (_objectSize / 2);
                          final centerY = _posY + (_objectSize / 2);

                          final isInsideTarget = centerX >= targetLeft &&
                              centerX <= (targetLeft + _targetSize) &&
                              centerY >= targetTop &&
                              centerY <= (targetTop + _targetSize);

                          if (isInsideTarget) {
                            setState(() {
                              _score += 10;
                              _posX = 40.0;
                              _posY = 40.0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tepat sasaran! +10 Poin.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: _objectSize,
                          height: _objectSize,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(_isDragging ? 75 : 35),
                                blurRadius: _isDragging ? 14 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
