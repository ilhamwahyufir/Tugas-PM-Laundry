import 'package:flutter/material.dart';
import 'api_service.dart';

class UserOrderHistoryPage extends StatefulWidget {
  final int userId;

  const UserOrderHistoryPage({super.key, required this.userId});

  @override
  State<UserOrderHistoryPage> createState() => _UserOrderHistoryPageState();
}

class _UserOrderHistoryPageState extends State<UserOrderHistoryPage> {
  List historyOrders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => loading = true);
    try {
      // ✅ PAKAI getOrderHistory() untuk ambil pesanan yang sudah dikonfirmasi
      final data = await ApiService.getOrderHistory(widget.userId);
      setState(() {
        historyOrders = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Menunggu Konfirmasi':
      case 'Menunggu Verifikasi':
        return Colors.orange;
      case 'Dibayar':
      case 'Diverifikasi':
        return Colors.blue;
      case 'Diproses':
        return Colors.purple;
      case 'Selesai':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget buildOrderCard(Map order) {
   
    final layanan = order['layanan'] ?? '-';
    final jumlah = order['jumlah'] ?? 0;
    final total = order['total'] ?? 0;
    final status = order['status'] ?? '-';
    final tanggal = order['tanggal'] ?? '-';
    final paymentMethod = order['payment_method'] ?? '-';

    // Parse tanggal
    String formattedDate = tanggal;
    try {
      final date = DateTime.parse(tanggal);
      formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Keep original if parsing fails
    }

    // Icon untuk payment method
    IconData paymentIcon = Icons.payment;
    if (paymentMethod == 'Cash') {
      paymentIcon = Icons.money;
    } else if (paymentMethod == 'Transfer') {
      paymentIcon = Icons.account_balance;
    } else if (paymentMethod == 'QRIS') {
      paymentIcon = Icons.qr_code_2;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Layanan
            Text(
              layanan,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Detail
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Jumlah: $jumlah',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            Row(
              children: [
                Icon(paymentIcon, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Pembayaran: $paymentMethod',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Rp ${formatRupiah(total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge "Selesai & Dikonfirmasi"
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text(
                    'Pesanan Selesai & Dikonfirmasi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : historyOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pesanan yang sudah selesai akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: historyOrders.length,
                    itemBuilder: (context, index) {
                      return buildOrderCard(historyOrders[index]);
                    },
                  ),
                ),
    );
  }
}