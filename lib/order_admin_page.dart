import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';

class OrderAdminPage extends StatefulWidget {
  const OrderAdminPage({super.key});

  @override
  State<OrderAdminPage> createState() => _OrderAdminPageState();
}

class _OrderAdminPageState extends State<OrderAdminPage> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() async {
    final data = await ApiService.getOrders();
    setState(() {
      orders = data;
      loading = false;
    });
  }

  void updateStatus(int orderId, String status) async {
    await ApiService.updateOrderStatus(orderId, status);
    loadOrders();
  }

  // =========================
  // 🖼️ SHOW QRIS FULLSCREEN
  // =========================
  void showQrisFullscreen(BuildContext context, String qrisFileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'http://localhost:3000/uploads/$qrisFileName',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Gagal memuat QRIS'),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 📋 COPY TO CLIPBOARD
  // =========================
  void copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $label berhasil disalin!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================
  // ➕ TAMBAH PESANAN MANUAL (ADMIN) - ✅ REVISED WITH BANK & QRIS CARDS
  // =========================
  void showAddOrderDialog() async {
    List users = [];
    List services = [];
    List paymentSettings = [];
    bool loadingData = true;

    try {
      users = await ApiService.getAllUsers();
      services = await ApiService.getServices();
      paymentSettings = await ApiService.getAllPaymentSettings();
      loadingData = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    dynamic selectedUser;
    bool isManualCustomer = false;
    final manualCustomerController = TextEditingController();
    
    dynamic selectedService;
    final jumlahController = TextEditingController();
    
    String paymentMethod = 'Cash';
    dynamic selectedBank;
    dynamic selectedQris;
    
    bool submitting = false;

    List bankList = paymentSettings
        .where((p) => p['payment_type'] == 'Transfer')
        .toList();
    List qrisList = paymentSettings
        .where((p) => p['payment_type'] == 'QRIS')
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper untuk calculate total
          int calculateTotal() {
            if (selectedService == null || jumlahController.text.isEmpty) {
              return 0;
            }
            final jumlah = int.tryParse(jumlahController.text) ?? 0;
            final harga = selectedService['harga'] as int;
            return jumlah * harga;
          }

          // Helper format rupiah
          String formatRupiah(int amount) {
            return amount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Colors.blue),
                SizedBox(width: 8),
                Text('Tambah Pesanan Manual'),
              ],
            ),
            content: loadingData
                ? const Center(
                    heightFactor: 2,
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CUSTOMER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pilih Customer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Input Manual',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Switch(
                                    value: isManualCustomer,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        isManualCustomer = val;
                                        if (val) {
                                          selectedUser = null;
                                        } else {
                                          manualCustomerController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          if (!isManualCustomer)
                            DropdownButtonFormField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                hintText: 'Pilih customer...',
                              ),
                              value: selectedUser,
                              items: users.map<DropdownMenuItem>((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text('${u['nama']} (${u['email']})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedUser = val;
                                });
                              },
                            ),
                          
                          if (isManualCustomer)
                            TextField(
                              controller: manualCustomerController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_add),
                                hintText: 'Ketik nama customer...',
                              ),
                            ),

                          const SizedBox(height: 16),

                          // LAYANAN
                          const Text(
                            'Layanan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_laundry_service),
                              hintText: 'Pilih layanan...',
                            ),
                            value: selectedService,
                            items: services.map<DropdownMenuItem>((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s['nama']} - Rp ${formatRupiah(s['harga'])}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedService = val;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // JUMLAH
                          const Text(
                            'Jumlah (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: jumlahController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                              hintText: 'Masukkan jumlah...',
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),

                          const SizedBox(height: 16),

                          // METODE PEMBAYARAN
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.payment),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Cash',
                                child: Text('Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'Transfer',
                                child: Text('Transfer Bank'),
                              ),
                              DropdownMenuItem(
                                value: 'QRIS',
                                child: Text('QRIS'),
                              ),
                            ],
                            onChanged: (val) {
                              setDialogState(() {
                                paymentMethod = val!;
                                selectedBank = null;
                                selectedQris = null;
                              });
                            },
                          ),

                          // =============================
                          // ✅ TAMPILAN BANK (CARD) - KAYAK USER
                          // =============================
                          if (paymentMethod == 'Transfer') ...[
                            const SizedBox(height: 16),
                            if (bankList.isEmpty)
                              const Text(
                                'Tidak ada bank tersedia',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              )
                            else
                              ...bankList.map((bank) {
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedBank = bank;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: selectedBank == bank
                                            ? [Colors.blue.shade100, Colors.blue.shade200]
                                            : [Colors.blue.shade50, Colors.blue.shade50],
                                      ),
                                      border: Border.all(
                                        color: selectedBank == bank
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                        width: selectedBank == bank ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.account_balance,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              bank['bank_name'] ?? 'Bank',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        const Text(
                                          'Nomor Rekening',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              bank['account_number'] ?? '-',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 18),
                                              onPressed: () {
                                                copyToClipboard(
                                                  context,
                                                  bank['account_number'] ?? '',
                                                  'Nomor rekening',
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Atas Nama',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bank['account_holder'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],

                          // =============================
                          // ✅ TAMPILAN QRIS (IMAGE + ZOOM) - KAYAK USER
                          // =============================
                          if (paymentMethod == 'QRIS') ...[
                            const SizedBox(height: 16),
                            if (qrisList.isEmpty)
                              const Text(
                                'Tidak ada QRIS tersedia',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              )
                            else
                              ...qrisList.map((qris) {
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedQris = qris;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: selectedQris == qris
                                            ? [Colors.purple.shade100, Colors.purple.shade200]
                                            : [Colors.purple.shade50, Colors.purple.shade50],
                                      ),
                                      border: Border.all(
                                        color: selectedQris == qris
                                            ? Colors.purple
                                            : Colors.grey.shade300,
                                        width: selectedQris == qris ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.purple,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Pembayaran QRIS',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (qris['qris_image'] != null &&
                                            qris['qris_image'] != '')
                                          GestureDetector(
                                            onTap: () {
                                              showQrisFullscreen(
                                                  context, qris['qris_image']);
                                            },
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                maxHeight: 180,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  'http://localhost:3000/uploads/${qris['qris_image']}',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child: Text(
                                                        'Gagal memuat QRIS'),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Text(
                                            'Gambar QRIS tidak tersedia',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap gambar untuk memperbesar',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],

                          const SizedBox(height: 16),

                          // TOTAL
                          if (selectedService != null &&
                              jumlahController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${formatRupiah(calculateTotal())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        // Validasi
                        String customerName = '';
                        int? userId;

                        if (isManualCustomer) {
                          if (manualCustomerController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama customer tidak boleh kosong'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          customerName = manualCustomerController.text.trim();
                        } else {
                          if (selectedUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih customer terlebih dahulu'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          customerName = selectedUser['nama'];
                          userId = selectedUser['id'];
                        }

                        if (selectedService == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih layanan terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (jumlahController.text.isEmpty ||
                            int.tryParse(jumlahController.text) == null ||
                            int.parse(jumlahController.text) <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jumlah harus lebih dari 0'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (paymentMethod == 'Transfer' && selectedBank == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih bank terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (paymentMethod == 'QRIS' && selectedQris == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pilih QRIS terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          submitting = true;
                        });

                        try {
                          final result = await ApiService.createOrderByAdmin(
                            userId ?? 0,
                            selectedService['nama'],
                            jumlahController.text,
                            selectedService['harga'],
                            paymentMethod,
                            manualCustomerName: isManualCustomer ? customerName : null,
                          );

                          if (!context.mounted) return;

                          if (result.containsKey('error')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['error']),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              submitting = false;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Pesanan berhasil ditambahkan untuk $customerName',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                            loadOrders();
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() {
                            submitting = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Buat Pesanan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // TOLAK PESANAN
  void tolakPesanan(int orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String alasan = '';
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Tolak Pesanan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mengapa pesanan ini ditolak?'),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Bukti pembayaran tidak valid',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => alasan = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, alasan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    final result = await ApiService.rejectOrder(orderId, reason);

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pesanan berhasil ditolak'),
          backgroundColor: Colors.orange,
        ),
      );
      loadOrders();
    }
  }

  // BATALKAN PESANAN
  void batalkanPesanan(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Batalkan Pesanan'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result =
        await ApiService.cancelOrder(orderId, 'Dibatalkan oleh admin');

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pesanan berhasil dibatalkan'),
          backgroundColor: Colors.red,
        ),
      );
      loadOrders();
    }
  }

  List<String> getStatusList(String paymentMethod) {
    if (paymentMethod == 'Cash') {
      return ['Diterima', 'Diproses', 'Selesai'];
    } else {
      return ['Menunggu Verifikasi', 'Dibayar', 'Diproses', 'Selesai'];
    }
  }

  List<String> allowedNextStatus(String current, List<String> statusList) {
    final index = statusList.indexOf(current);
    if (index == -1) {
      return [statusList.first];
    }
    final end =
        (index + 2 <= statusList.length) ? index + 2 : statusList.length;
    return statusList.sublist(0, end);
  }

  

  // =========================
  // 🔍 LIHAT BUKTI
  // =========================
  void showBukti(String fileName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bukti Pembayaran'),
        content: Image.network(
          'http://localhost:3000/uploads/$fileName',
          errorBuilder: (_, __, ___) => const Text('Gagal memuat gambar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // =========================
  // ✅ KONFIRMASI PEMBAYARAN
  // =========================
  void konfirmasiPembayaran(int orderId) async {
    await ApiService.updateOrderStatus(orderId, 'Dibayar');
    loadOrders();
  }

  // =========================
  // 📋 SHOW DETAIL POPUP
  // =========================
  void showDetailPopup(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Pesanan #${order['id']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                _buildDetailRow('Nama Customer', order['customer_name'] ?? '-'),
                _buildDetailRow('Email', order['customer_email'] ?? '-'),
                _buildDetailRow(
                  'Tanggal',
                  order['tanggal'] != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(
                          DateTime.parse(order['tanggal']),
                        )
                      : '-',
                ),
                _buildDetailRow('Layanan', order['layanan'] ?? '-'),
                _buildDetailRow('Jumlah', '${order['jumlah']} kg'),
                _buildDetailRow(
                  'Harga per kg',
                  'Rp ${NumberFormat('#,###').format(order['harga'] ?? 0)}',
                ),
                _buildDetailRow(
                  'Total',
                  'Rp ${NumberFormat('#,###').format(order['total'] ?? 0)}',
                  isBold: true,
                ),
                _buildDetailRow(
                  'Metode Pembayaran',
                  order['payment_method'] ?? 'Cash',
                ),
                _buildDetailRow(
                  'Status Pembayaran',
                  order['payment_status'] ?? 'Belum Dibayar',
                ),
                _buildDetailRow('Status Pesanan', order['status'] ?? '-'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _printStruk(order);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🖨️ CETAK STRUK
  // =========================
  Future<void> _printStruk(dynamic order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'LAUNDRY SETRIKA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Jl. Contoh No. 123'),
              pw.Text('Telp: 0812-3456-7890'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              _buildPdfRow('No. Order', '#${order['id']}'),
              _buildPdfRow(
                'Tanggal',
                order['tanggal'] != null
                    ? DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(order['tanggal']))
                    : '-',
              ),
              _buildPdfRow('Nama', order['customer_name'] ?? '-'),
              pw.Divider(),
              _buildPdfRow('Layanan', order['layanan'] ?? '-'),
              _buildPdfRow('Jumlah', '${order['jumlah']} kg'),
              _buildPdfRow(
                'Harga',
                'Rp ${NumberFormat('#,###').format(order['harga'] ?? 0)}',
              ),
              pw.Divider(),
              _buildPdfRow(
                'TOTAL',
                'Rp ${NumberFormat('#,###').format(order['total'] ?? 0)}',
                isBold: true,
              ),
              _buildPdfRow(
                'Metode Pembayaran',
                order['payment_method'] ?? 'Cash',
              ),
              _buildPdfRow(
                'Status Pembayaran',
                order['payment_status'] ?? 'Belum Dibayar',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Terima Kasih',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Simpan struk ini sebagai bukti',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk_Order_${order['id']}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Laundry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddOrderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pesanan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('Belum ada pesanan'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final paymentMethod = o['payment_method'] ?? 'Cash';
                    final statusList = getStatusList(paymentMethod);
                    final currentStatus = statusList.contains(o['status'])
                        ? o['status']
                        : statusList.first;
                    final allowedStatus =
                        allowedNextStatus(currentStatus, statusList);

                    final isDitolak = o['status'] == 'Ditolak';
                    final isDibatalkan = o['status'] == 'Dibatalkan';
                    final isRejectedOrCancelled = isDitolak || isDibatalkan;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: isRejectedOrCancelled ? Colors.red[50] : null,
                      child: InkWell(
                        onTap: () => showDetailPopup(o),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o['layanan'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nama: ${o['customer_name'] ?? 'Tidak diketahui'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jumlah: ${o['jumlah']} | Total: Rp ${o['total']}',
                              ),
                              Text(
                                'Metode: $paymentMethod',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (isRejectedOrCancelled)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isDitolak ? 'DITOLAK' : 'DIBATALKAN',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (paymentMethod == 'Transfer' &&
                                  o['bukti_bayar'] != null &&
                                  o['bukti_bayar'] != '')
                                TextButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text('Lihat Bukti Pembayaran'),
                                  onPressed: () => showBukti(o['bukti_bayar']),
                                ),
                              if (paymentMethod == 'Transfer' &&
                                  o['status'] == 'Menunggu Verifikasi')
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle,
                                            size: 18),
                                        label: const Text('Terima'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () =>
                                            konfirmasiPembayaran(o['id']),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.cancel, size: 18),
                                        label: const Text('Tolak'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () => tolakPesanan(o['id']),
                                      ),
                                    ),
                                  ],
                                ),
                             
                              if (!isRejectedOrCancelled &&
                                  o['status'] != 'Menunggu Verifikasi' &&
                                  o['status'] != 'Selesai')
                                TextButton.icon(
                                  icon: const Icon(Icons.block, size: 18),
                                  label: const Text('Batalkan Pesanan'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () => batalkanPesanan(o['id']),
                                ),

                              const Divider(),

                              if (!isRejectedOrCancelled)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Status:'),
                                    DropdownButton<String>(
                                      value: currentStatus,
                                      items: allowedStatus.map((status) {
                                        return DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null && val != currentStatus) {
                                          updateStatus(o['id'], val);
                                        }
                                      },
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Status:'),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        o['status'],
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
}