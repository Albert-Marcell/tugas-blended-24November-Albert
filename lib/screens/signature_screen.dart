import 'package:flutter/material.dart';

// Satu goresan = kumpulan titik + warna pena yang dipakai
class Stroke {
  final List<Offset> points;
  final Color color;

  Stroke({required this.color}) : points = [];
}

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final List<Stroke> _strokes = [];

  // 3 pilihan warna pena
  final List<Color> _penColors = const [
    Color(0xFF0F172A), // Hitam
    Color(0xFF2563EB), // Biru
    Color(0xFFDC2626), // Merah
  ];
  final List<String> _penNames = const ['Hitam', 'Biru', 'Merah'];
  int _selectedColor = 0;

  void _clearCanvas() {
    setState(() => _strokes.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kanvas berhasil dihapus.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen 5: Tanda Tangan Digital'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Gunakan jari Anda untuk menulis tanda tangan di dalam kotak.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            // Area Kanvas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    // onPanStart: mulai goresan baru
                    onPanStart: (details) {
                      setState(() {
                        _strokes.add(
                          Stroke(color: _penColors[_selectedColor])
                            ..points.add(details.localPosition),
                        );
                      });
                    },
                    // onPanUpdate: tambah titik ke goresan terakhir
                    onPanUpdate: (details) {
                      setState(() {
                        _strokes.last.points.add(details.localPosition);
                      });
                    },
                    // onPanEnd: goresan selesai
                    onPanEnd: (_) {
                      setState(() {});
                    },
                    child: CustomPaint(
                      painter: SignaturePainter(_strokes),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Pilihan Warna Pena
            Row(
              children: [
                const Text(
                  'Warna Pena:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ...List.generate(_penColors.length, (i) {
                  final isActive = i == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = i),
                    child: Tooltip(
                      message: _penNames[i],
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 10),
                        width: isActive ? 36 : 30,
                        height: isActive ? 36 : 30,
                        decoration: BoxDecoration(
                          color: _penColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? const Color(0xFFFBBF24) : Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            // Tombol Hapus Kanvas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _strokes.isEmpty ? null : _clearCanvas,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Kanvas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter untuk menggambar semua goresan
class SignaturePainter extends CustomPainter {
  final List<Stroke> strokes;

  SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        // Ketukan tunggal digambar sebagai titik
        canvas.drawCircle(stroke.points.first, 1.75, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
