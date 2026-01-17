import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  bool loading = false;
  int totalPesanan = 0;
  int totalPendapatan = 0;
  List laporan = [];
  String errorMessage = '';

  DateTime selectedDate = DateTime.now();
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadHarian();
  }

  // =====================
  // LAPORAN HARIAN
  // =====================
  Future<void> loadHarian() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final date = DateFormat('yyyy-MM-dd').format(selectedDate);
      print('🔵 Loading harian untuk tanggal: $date');

      final result = await ApiService.getDailyReport(date);

      print('🔵 Result: $result');

      if (mounted) {
        setState(() {
          totalPesanan = result['total_pesanan'] ?? 0;
          totalPendapatan = result['total_pendapatan'] ?? 0;
          laporan = result['data'] ?? [];
          errorMessage = result['error'] ?? '';
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loadHarian: $e');
      if (mounted) {
        setState(() {
          totalPesanan = 0;
          totalPendapatan = 0;
          laporan = [];
          errorMessage = 'Terjadi kesalahan: $e';
          loading = false;
        });
      }
    }
  }

  // =====================
  // LAPORAN BULANAN
  // =====================
  Future<void> loadBulanan() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      print('🔵 Loading bulanan untuk: ${selectedMonth.year}-${selectedMonth.month}');

      final result = await ApiService.getMonthlyReport(
        selectedMonth.year,
        selectedMonth.month,
      );

      print('🔵 Result: $result');

      if (mounted) {
        setState(() {
          totalPesanan = result['total_pesanan'] ?? 0;
          totalPendapatan = result['total_pendapatan'] ?? 0;
          laporan = result['data'] ?? [];
          errorMessage = result['error'] ?? '';
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loadBulanan: $e');
      if (mounted) {
        setState(() {
          totalPesanan = 0;
          totalPendapatan = 0;
          laporan = [];
          errorMessage = 'Terjadi kesalahan: $e';
          loading = false;
        });
      }
    }
  }

  // =====================
  // PICK DATE
  // =====================
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      loadHarian();
    }
  }

  // =====================
  // PICK MONTH
  // =====================
  Future<void> pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
      });
      loadBulanan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Laundry'),
        bottom: TabBar(
          controller: tabController,
          onTap: (i) => i == 0 ? loadHarian() : loadBulanan(),
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Bulanan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          buildReport(
            title: 'Tanggal',
            dateText: DateFormat('dd MMM yyyy').format(selectedDate),
            onPick: pickDate,
          ),
          buildReport(
            title: 'Bulan',
            dateText: DateFormat('MMMM yyyy').format(selectedMonth),
            onPick: pickMonth,
          ),
        ],
      ),
    );
  }

  Widget buildReport({
    required String title,
    required String dateText,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: $dateText',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Pilih Tanggal'),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pesanan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalPesanan',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pendapatan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(totalPendapatan)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Text(
            'Detail Pesanan:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : laporan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada data pesanan yang selesai',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pastikan ada pesanan dengan status "Selesai"',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: laporan.length,
                        itemBuilder: (_, i) {
                          final o = laporan[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${i + 1}'),
                              ),
                              title: Text(
                                o['layanan'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Jumlah: ${o['jumlah']} kg',
                              ),
                              trailing: Text(
                                'Rp ${NumberFormat('#,###').format(o['total'] ?? 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}