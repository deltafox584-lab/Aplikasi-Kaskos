// File: lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Analisis Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada data untuk dianalisis.', style: TextStyle(color: Color(0xFF94A3B8))),
            );
          }

          final Map<String, int> categoryTotals = {};
          int totalAll = 0;

          for (var tx in provider.transactions) {
            categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
            totalAll += tx.amount;
          }

          final List<Color> neonColors = [
            const Color(0xFF00E5FF),
            const Color(0xFF00E676),
            const Color(0xFFFF4081),
            const Color(0xFFFFD700),
            const Color(0xFF7C4DFF),
            const Color(0xFFFF6E40),
          ];

          int colorIndex = 0;
          final sections = categoryTotals.entries.map((entry) {
            final double percentage = totalAll == 0 ? 0 : (entry.value / totalAll) * 100;
            final color = neonColors[colorIndex % neonColors.length];
            colorIndex++;

            return PieChartSectionData(
              color: color,
              value: entry.value.toDouble(),
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 55,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 45,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rincian per Kategori',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...categoryTotals.entries.map((entry) {
                final double percentage = totalAll == 0 ? 0 : (entry.value / totalAll) * 100;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(entry.value), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                          Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}