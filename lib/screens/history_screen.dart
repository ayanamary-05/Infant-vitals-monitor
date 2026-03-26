import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:first_app/main.dart' show tempUnitNotifier, languageNotifier;
import 'package:first_app/screens/app_strings.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color _bg       = Color(0xFF0F172A);
const Color _surface  = Color(0xFF1E293B);
const Color _border   = Color(0xFF334155);
const Color _textMain = Color(0xFFF1F5F9);
const Color _textSub  = Color(0xFF94A3B8);

// ── Time Range ─────────────────────────────────────────────────────────────
enum TimeRange { h24, d7, d30 }

extension TimeRangeExt on TimeRange {
  String get label => switch (this) {
    TimeRange.h24 => '24 Hours',
    TimeRange.d7  => '7 Days',
    TimeRange.d30 => '30 Days',
  };
  int get points => switch (this) {
    TimeRange.h24 => 24,
    TimeRange.d7  => 7,
    TimeRange.d30 => 30,
  };
}

// ── Vital definition ───────────────────────────────────────────────────────
class _VitalDef {
  final String label;
  final Color color;
  final double minY;
  final double maxY;
  final String unit;
  final double Function(double raw, bool isFahrenheit) displayValue;
  final String Function(bool isFahrenheit) unitLabel;

  const _VitalDef({
    required this.label,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.unit,
    required this.displayValue,
    required this.unitLabel,
  });
}

final _vitalDefs = [
  _VitalDef(
    label: 'Heart Rate',
    color: const Color(0xFFEF4444),
    minY: 80, maxY: 180,
    unit: 'BPM',
    displayValue: (raw, _) => raw,
    unitLabel: (_) => 'BPM',
  ),
  _VitalDef(
    label: 'Temperature',
    color: const Color(0xFFF59E0B),
    minY: 35, maxY: 40,
    unit: '°C',
    displayValue: (raw, isFahrenheit) => isFahrenheit ? raw * 9 / 5 + 32 : raw,
    unitLabel: (isFahrenheit) => isFahrenheit ? '°F' : '°C',
  ),
  _VitalDef(
    label: 'SpO2',
    color: const Color(0xFF3B82F6),
    minY: 85, maxY: 100,
    unit: '%',
    displayValue: (raw, _) => raw,
    unitLabel: (_) => '%',
  ),
];

// ── Annotation model ───────────────────────────────────────────────────────
class _Annotation {
  final int pointIndex;
  final String note;
  _Annotation({required this.pointIndex, required this.note});
}

// ── Screen ─────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _vitalIndex = 0;
  TimeRange _timeRange = TimeRange.h24;
  int? _touchedIndex;
  final List<_Annotation> _annotations = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    languageNotifier.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    languageNotifier.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _exportData(bool asPdf) async {
    setState(() => _isExporting = true);
    try {
      final isFahrenheit = tempUnitNotifier.value == 'Fahrenheit';
      final rawData = _data;
      final displayData = rawData.map((v) => _def.displayValue(v, isFahrenheit)).toList();
      final unitLabel = _def.unitLabel(isFahrenheit);
      final vitalName = _def.label;
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      final safeVital = vitalName.toLowerCase().replaceAll(' ', '_');

      if (asPdf) {
        final doc = pw.Document();
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Infant Vitals — $vitalName History',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Date: $dateStr  |  Range: ${_timeRange.label}  |  Unit: $unitLabel',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['#', 'Value ($unitLabel)'],
                data: List.generate(displayData.length,
                    (i) => [(i + 1).toString(), displayData[i].toStringAsFixed(_dp)]),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
        ));
        final bytes = await doc.save();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/vitals_${safeVital}_$dateStr.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Infant Vitals — $vitalName');
      } else {
        final buf = StringBuffer();
        buf.writeln('Point,Value ($unitLabel),Date');
        final nowDate = DateTime.now();
        for (int i = 0; i < displayData.length; i++) {
          String lbl;
          if (_timeRange == TimeRange.h24) {
            final hour = (nowDate.hour - (displayData.length - 1 - i) + 24) % 24;
            lbl = '$hour:00';
          } else {
            final d = nowDate.subtract(Duration(days: displayData.length - 1 - i));
            lbl = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
          }
          buf.writeln('${i + 1},${displayData[i].toStringAsFixed(_dp)},$lbl');
        }
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/vitals_${safeVital}_$dateStr.csv');
        await file.writeAsString(buf.toString());
        await Share.shareXFiles([XFile(file.path)], text: 'Infant Vitals — $vitalName');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(AppStrings.t('export_title'),
                style: const TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF1DB954)),
              title: Text(AppStrings.t('export_csv'),
                  style: const TextStyle(color: _textMain, fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _exportData(false); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFFF6B6B)),
              title: Text(AppStrings.t('export_pdf'),
                  style: const TextStyle(color: _textMain, fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _exportData(true); },
            ),
          ],
        ),
      ),
    );
  }

  // Generate simulated demo data based on vital + time range
  List<double> _generateData(int vitalIndex, TimeRange range) {
    final rng = math.Random(vitalIndex * 100 + range.index);
    final def = _vitalDefs[vitalIndex];
    final mid = (def.minY + def.maxY) / 2;
    final spread = (def.maxY - def.minY) * 0.15;
    return List.generate(range.points, (i) {
      double v = mid + (rng.nextDouble() - 0.5) * 2 * spread;
      // Add some realistic drift over time
      v += math.sin(i * 0.3) * spread * 0.3;
      return v.clamp(def.minY, def.maxY);
    });
  }

  List<double> get _data => _generateData(_vitalIndex, _timeRange);

  // stats computed in build from displayData so unit conversion is applied

  bool get _isTemp => _vitalIndex == 1;
  int  get _dp     => _isTemp ? 1 : 0;

  _VitalDef get _def => _vitalDefs[_vitalIndex];

  void _addAnnotation(int pointIndex) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Note', style: TextStyle(color: _textMain, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: _textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. after feeding',
            hintStyle: const TextStyle(color: _textSub),
            filled: true, fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _def.color),
            ),
          ),

        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel', style: TextStyle(color: _textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _def.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() {
        _annotations.removeWhere((a) => a.pointIndex == pointIndex);
        _annotations.add(_Annotation(pointIndex: pointIndex, note: result));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: tempUnitNotifier,
      builder: (_, tempUnit, __) {
        final isFahrenheit = tempUnit == 'Fahrenheit';
        final rawData = _data;
        final displayData = rawData.map((v) =>
            _def.displayValue(v, isFahrenheit)).toList();
        final unitLabel = _def.unitLabel(isFahrenheit);

        final displayMin = displayData.reduce(math.min);
        final displayMax = displayData.reduce(math.max);
        final displayAvg = displayData.reduce((a, b) => a + b) / displayData.length;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('vitals_history'),
                    style: const TextStyle(color: _textMain, fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(AppStrings.t('historical_trends'),
                    style: const TextStyle(color: _textSub, fontSize: 11)),
              ],
            ),
            actions: [
              if (_isExporting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F8EF7))),
                )
              else
                IconButton(
                  onPressed: _showExportSheet,
                  icon: const Icon(Icons.ios_share_rounded, color: Color(0xFF4F8EF7), size: 20),
                  tooltip: AppStrings.t('export'),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _border),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vital selector tabs ────────────────────
                _VitalTabBar(
                  selected: _vitalIndex,
                  onTap: (i) => setState(() {
                    _vitalIndex = i;
                    _touchedIndex = null;
                  }),
                ),
                const SizedBox(height: 16),

                // ── Time range toggles ─────────────────────
                _TimeRangeBar(
                  selected: _timeRange,
                  accentColor: _def.color,
                  onTap: (r) => setState(() {
                    _timeRange = r;
                    _touchedIndex = null;
                  }),
                ),
                const SizedBox(height: 20),

                // ── Chart ──────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _timeRange.label,
                            style: const TextStyle(
                                color: _textSub, fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                          if (_touchedIndex != null)
                            TextButton.icon(
                              onPressed: () => _addAnnotation(_touchedIndex!),
                              icon: const Icon(Icons.note_add_outlined, size: 14),
                              label: const Text('Add Note', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: _def.color,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: GestureDetector(
                          onTapDown: (details) {
                            final box = context.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            // Calculate touched index from x position
                            final localX = details.localPosition.dx;
                            final chartWidth = box.size.width - 32; // approx
                            if (chartWidth <= 0) return;
                            final idx = ((localX / chartWidth) * (displayData.length - 1))
                                .round().clamp(0, displayData.length - 1);
                            setState(() => _touchedIndex = idx);
                          },
                          child: _LineChart(
                            data: displayData,
                            color: _def.color,
                            touchedIndex: _touchedIndex,
                            annotations: _annotations,
                            unitLabel: unitLabel,
                            decimals: _dp,
                            timeRange: _timeRange,
                          ),
                        ),
                      ),
                      // Touched point info
                      if (_touchedIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: _def.color, shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Point ${_touchedIndex! + 1}: ${displayData[_touchedIndex!].toStringAsFixed(_dp)} $unitLabel',
                                style: TextStyle(color: _def.color, fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              // Show annotation if exists
                              Builder(builder: (_) {
                                final ann = _annotations.where(
                                    (a) => a.pointIndex == _touchedIndex).firstOrNull;
                                return ann != null
                                    ? Text('📝 ${ann.note}',
                                        style: const TextStyle(
                                            color: _textSub, fontSize: 11))
                                    : const SizedBox.shrink();
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats ──────────────────────────────────
                Row(children: [
                  _StatCard(
                    label: 'Min', unit: unitLabel,
                    value: displayMin.toStringAsFixed(_dp),
                    color: const Color(0xFF4F8EF7),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Avg', unit: unitLabel,
                    value: displayAvg.toStringAsFixed(_dp),
                    color: _def.color,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Max', unit: unitLabel,
                    value: displayMax.toStringAsFixed(_dp),
                    color: const Color(0xFFEF4444),
                  ),
                ]),

                // ── Annotations list ───────────────────────
                if (_annotations.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Notes',
                      style: TextStyle(color: _textMain, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._annotations.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 14, color: _def.color),
                      const SizedBox(width: 8),
                      Text('Point ${a.pointIndex + 1}: ',
                          style: TextStyle(color: _def.color, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(a.note,
                          style: const TextStyle(color: _textSub, fontSize: 12)),
                    ]),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Canvas Line Chart ──────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final int? touchedIndex;
  final List<_Annotation> annotations;
  final String unitLabel;
  final int decimals;
  final TimeRange timeRange;

  const _LineChart({
    required this.data,
    required this.color,
    required this.touchedIndex,
    required this.annotations,
    required this.unitLabel,
    required this.decimals,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(
        data: data,
        color: color,
        touchedIndex: touchedIndex,
        annotations: annotations,
        decimals: decimals,
        timeRange: timeRange,
      ),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final int? touchedIndex;
  final List<_Annotation> annotations;
  final int decimals;
  final TimeRange timeRange;

  static const _yAxisWidth = 38.0;
  static const _xAxisHeight = 24.0;

  _ChartPainter({
    required this.data,
    required this.color,
    required this.touchedIndex,
    required this.annotations,
    required this.decimals,
    required this.timeRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartW = size.width - _yAxisWidth;
    final chartH = size.height - _xAxisHeight;
    final left   = _yAxisWidth;
    final top    = 0.0;

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range  = (maxVal - minVal).clamp(1.0, double.infinity);

    // helpers
    double xOf(int i) => left + (i / (data.length - 1)) * chartW;
    double yOf(double v) => top + chartH - ((v - minVal) / range) * chartH * 0.85 - chartH * 0.07;

    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 0.8;

    // ── Grid lines ────────────────────────────────────────────────────────
    for (int i = 0; i <= 4; i++) {
      final y = top + (i / 4) * chartH;
      canvas.drawLine(Offset(left, y), Offset(left + chartW, y), gridPaint);
    }

    // ── Y-axis labels ─────────────────────────────────────────────────────
    final yLabelStyle = TextStyle(color: const Color(0xFF94A3B8), fontSize: 9);
    for (int i = 0; i <= 4; i++) {
      final val = minVal + (1 - i / 4) * range;
      final tp  = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(decimals), style: yLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - 4, top + (i / 4) * chartH - tp.height / 2));
    }

    // ── X-axis labels ─────────────────────────────────────────────────────
    final xLabelStyle = TextStyle(color: const Color(0xFF94A3B8), fontSize: 9);
    final labelCount  = math.min(6, data.length);
    for (int li = 0; li < labelCount; li++) {
      final i    = (li * (data.length - 1) / (labelCount - 1)).round();
      final x    = xOf(i);
      String lbl;
      if (timeRange == TimeRange.h24) {
        final now  = DateTime.now();
        final hour = (now.hour - (data.length - 1 - i) + 24) % 24;
        lbl = '$hour:00';
      } else {
        final now = DateTime.now();
        final d   = now.subtract(Duration(days: data.length - 1 - i));
        lbl = '${d.month}/${d.day}';
      }
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: xLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, top + chartH + 4));
    }

    // ── Gradient fill ─────────────────────────────────────────────────────
    final path = Path()..moveTo(xOf(0), yOf(data[0]));
    for (int i = 1; i < data.length; i++) {
      final xi = xOf(i); final yi = yOf(data[i]);
      final xPrev = xOf(i - 1); final yPrev = yOf(data[i - 1]);
      final cpX1 = xPrev + (xi - xPrev) / 2;
      path.cubicTo(cpX1, yPrev, cpX1, yi, xi, yi);
    }
    final fillPath = Path.from(path)
      ..lineTo(xOf(data.length - 1), top + chartH)
      ..lineTo(left, top + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(left, top, chartW, chartH)),
    );

    // ── Line ──────────────────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Annotation dots ───────────────────────────────────────────────────
    for (final ann in annotations) {
      if (ann.pointIndex < data.length) {
        final x = xOf(ann.pointIndex);
        final y = yOf(data[ann.pointIndex]);
        canvas.drawCircle(
          Offset(x, y), 5,
          Paint()..color = const Color(0xFFA78BFA),
        );
      }
    }

    // ── Touched point ─────────────────────────────────────────────────────
    if (touchedIndex != null && touchedIndex! < data.length) {
      final x = xOf(touchedIndex!);
      final y = yOf(data[touchedIndex!]);
      // vertical dashed line (drawn manually — PathDashEffect not in Flutter)
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      const dashH = 5.0;
      const gapH  = 4.0;
      double dy = top;
      while (dy < top + chartH) {
        canvas.drawLine(
          Offset(x, dy),
          Offset(x, (dy + dashH).clamp(top, top + chartH)),
          dashPaint,
        );
        dy += dashH + gapH;
      }
      // outer ring
      canvas.drawCircle(Offset(x, y), 8,
          Paint()..color = color.withValues(alpha: 0.25));
      // inner dot
      canvas.drawCircle(Offset(x, y), 5,
          Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.touchedIndex != touchedIndex ||
      old.data != data ||
      old.annotations.length != annotations.length;
}

// ── Vital Tab Bar ──────────────────────────────────────────────────────────
class _VitalTabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _VitalTabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(_vitalDefs.length, (i) {
          final isActive = i == selected;
          final def = _vitalDefs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive ? def.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                child: Text(
                  def.label,
                  style: TextStyle(
                    color: isActive ? Colors.white : _textSub,
                    fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Time Range Bar ─────────────────────────────────────────────────────────
class _TimeRangeBar extends StatelessWidget {
  final TimeRange selected;
  final Color accentColor;
  final ValueChanged<TimeRange> onTap;
  const _TimeRangeBar({
    required this.selected, required this.accentColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TimeRange.values.map((r) {
        final isSel = r == selected;
        return Padding(
          padding: EdgeInsets.only(right: r != TimeRange.d30 ? 8 : 0),
          child: GestureDetector(
            onTap: () => onTap(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSel ? accentColor.withValues(alpha: 0.15) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? accentColor : _border,
                ),
              ),
              child: Text(
                r.label,
                style: TextStyle(
                  color: isSel ? accentColor : _textSub,
                  fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard({
    required this.label, required this.value,
    required this.color, required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: _textSub, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(unit,
                style: const TextStyle(color: _textSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}