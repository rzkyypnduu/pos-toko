import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/transaksi_provider.dart';
import '../utils/formatters.dart';

const _colorGross = Color(0xFF1565C0);
const _colorNet = Color(0xFF2E7D32);
const _monthNames = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

class MonthlyProfitChart extends StatelessWidget {
  final List<MonthlyProfitData> data;
  const MonthlyProfitChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(0, (m, d) {
      final high = d.gross > d.net ? d.gross : d.net;
      return high > m ? high : m;
    });
    final topY = maxY == 0 ? 100000.0 : (maxY * 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topY,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[groupIndex];
                    final label =
                        '${_monthNames[item.month]} ${item.year}\n${rodIndex == 0 ? 'Kotor' : 'Bersih'}: ${formatRupiah(rod.toY)}';
                    return BarTooltipItem(
                      label,
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        _compactRupiah(value),
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _monthNames[data[idx].month],
                          style: const TextStyle(
                              fontSize: 9, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: topY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].gross,
                      color: _colorGross,
                      width: data.length > 8 ? 6 : 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: data[i].net,
                      color: _colorNet,
                      width: data.length > 8 ? 6 : 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(_colorGross, 'Kotor'),
        const SizedBox(width: 14),
        _legendDot(_colorNet, 'Bersih'),
      ],
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  static String _compactRupiah(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toInt().toString();
  }
}

class DailyProfitChart extends StatelessWidget {
  final List<DailyProfitData> data;
  const DailyProfitChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Belum ada data',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    final maxY = data.fold<double>(0, (m, d) {
      final high = d.gross > d.net ? d.gross : d.net;
      return high > m ? high : m;
    });
    final topY = maxY == 0 ? 100000.0 : (maxY * 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyProfitChart._buildLegend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: topY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final day = data[spot.x.toInt()].day;
                      final label =
                          'Tgl $day\n${spot.barIndex == 0 ? 'Kotor' : 'Bersih'}: ${formatRupiah(spot.y)}';
                      return LineTooltipItem(
                        label,
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: topY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        MonthlyProfitChart._compactRupiah(value),
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: data.length > 15 ? 5 : 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final d = data[idx].day;
                      if (data.length > 15 && d % 5 != 0 && d != data.last.day) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$d',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: topY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      data.length, (i) => FlSpot(i.toDouble(), data[i].gross)),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: _colorGross,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _colorGross.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(
                      data.length, (i) => FlSpot(i.toDouble(), data[i].net)),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: _colorNet,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _colorNet.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
