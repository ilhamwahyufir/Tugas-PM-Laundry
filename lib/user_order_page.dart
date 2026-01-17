import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class UserOrderPage extends StatefulWidget {
  final int userId;

  const UserOrderPage({super.key, required this.userId});

  @override
  State<UserOrderPage> createState() => _UserOrderPageState();
}

class _UserOrderPageState extends State<UserOrderPage> {
  final TextEditingController jumlahController = TextEditingController();

  List services = [];
  dynamic selectedService;

  String paymentMethod = 'Cash';
  XFile? buktiBayar;

  bool loading = true;
  bool submitting = false;
  String message = '';

  // 🆕 DYNAMIC PAYMENT INFO
  List<dynamic> bankAccounts = [];
  dynamic qrisData;
  bool loadingPaymentInfo = false;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final data = await ApiService.getServices();
      setState(() {
        services = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        message = 'Gagal memuat layanan: $e';
      });
    }
  }

  // 🆕 LOAD PAYMENT INFO DARI API
  Future<void> loadPaymentInfo(String type) async {
    setState(() {
      loadingPaymentInfo = true;
    });

    try {
      final data = await ApiService.getPaymentSettings(type);
      
      setState(() {
        if (type == 'Transfer') {
          bankAccounts = data;
        } else if (type == 'QRIS') {
          qrisData = data.isNotEmpty ? data[0] : null;
        }
        loadingPaymentInfo = false;
      });
    } catch (e) {
      setState(() {
        loadingPaymentInfo = false;
        message = 'Gagal memuat info pembayaran: $e';
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        buktiBayar = picked;
      });
    }
  }

  // 📋 COPY TO CLIPBOARD
  void copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 💰 HITUNG TOTAL
  int calculateTotal() {
    if (selectedService == null || jumlahController.text.isEmpty) {
      return 0;
    }
    final jumlah = int.tryParse(jumlahController.text) ?? 0;
    final harga = selectedService['harga'] as int;
    return jumlah * harga;
  }

  // 💰 FORMAT RUPIAH
  String formatRupiah(int amount) {
    return amount
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')
        .toString();
  }

  Future<void> submitOrder() async {
    if (selectedService == null || jumlahController.text.isEmpty) {
      setState(() {
        message = 'Lengkapi data pesanan';
      });
      return;
    }

    final jumlah = int.tryParse(jumlahController.text);
    if (jumlah == null || jumlah <= 0) {
      setState(() {
        message = 'Jumlah harus berupa angka positif';
      });
      return;
    }

    if ((paymentMethod == 'Transfer' || paymentMethod == 'QRIS') && buktiBayar == null) {
      setState(() {
        message = 'Upload bukti pembayaran terlebih dahulu';
      });
      return;
    }

    setState(() {
      submitting = true;
      message = '';
    });

    try {
      final res = await ApiService.createOrder(
        widget.userId,
        selectedService['nama'],
        jumlahController.text,
        selectedService['harga'],
        paymentMethod,
      );

      if (res.containsKey('error')) {
        setState(() {
          message = 'Error: ${res['error']}';
          submitting = false;
        });
        return;
      }

      if (res.containsKey('message') && res['id'] == null) {
        setState(() {
          message = res['message'];
          submitting = false;
        });
        return;
      }

      if (res['id'] != null) {
        final int orderId = res['id'];

        if ((paymentMethod == 'Transfer' || paymentMethod == 'QRIS') && buktiBayar != null) {
          try {
            final uploadRes = await ApiService.uploadPaymentProof(orderId, buktiBayar!);

            if (uploadRes.containsKey('error')) {
              setState(() {
                message = 'Pesanan dibuat tapi upload bukti gagal: ${uploadRes['error']}';
                submitting = false;
              });
              
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                Navigator.pop(context, true);
              }
              return;
            }
          } catch (uploadError) {
            setState(() {
              message = 'Pesanan dibuat tapi upload bukti gagal: $uploadError';
              submitting = false;
            });
            
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pop(context, true);
            }
            return;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          message = 'Gagal membuat pesanan - tidak ada ID dari server';
          submitting = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Terjadi kesalahan: $e';
        submitting = false;
      });
    }
  }

  // 🎨 WIDGET INFO TRANSFER - DYNAMIC (FIXED)
  Widget buildTransferInfo() {
    if (loadingPaymentInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bankAccounts.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Info rekening bank tidak tersedia',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
                onPressed: () => loadPaymentInfo('Transfer'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ FIX: Buat List<Widget> dengan cara yang benar
    final List<Widget> widgets = [];

    // Tambahkan card untuk setiap bank
    for (var bank in bankAccounts) {
      widgets.add(
        Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      bank['bank_name'] ?? 'Bank',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 30, thickness: 1),

                // Account Number
                const Text(
                  'Nomor Rekening',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bank['account_number'] ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => copyToClipboard(
                        bank['account_number'] ?? '', 
                        'Nomor rekening'
                      ),
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      tooltip: 'Salin nomor rekening',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Account Name
                const Text(
                  'Atas Nama',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  bank['account_holder'] ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tambahkan Total Payment
    widgets.add(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Rp ${formatRupiah(calculateTotal())}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );

    widgets.add(const SizedBox(height: 12));

    // Tambahkan Instructions
    widgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Transfer sesuai nominal di atas ke salah satu rekening dan upload bukti pembayaran',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(children: widgets);
  }

  // 🎨 WIDGET INFO QRIS - DYNAMIC
  Widget buildQrisInfo() {
    if (loadingPaymentInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (qrisData == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Info QRIS tidak tersedia',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
                onPressed: () => loadPaymentInfo('QRIS'),
              ),
            ],
          ),
        ),
      );
    }

    final qrisImage = qrisData['qris_image'];
    final qrisUrl = qrisImage != null 
        ? 'http://localhost:3000/uploads/$qrisImage'
        : null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pembayaran QRIS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // QR Code Image
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: qrisUrl != null
                  ? Image.network(
                      qrisUrl,
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 250,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('QR Code Tidak Tersedia'),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('QR Code Belum Diupload'),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Rp ${formatRupiah(calculateTotal())}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan QR code dengan aplikasi pembayaran digital Anda (GoPay, OVO, Dana, dll)',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
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
        title: const Text('Buat Pesanan Laundry'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // LAYANAN
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      labelText: 'Layanan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_laundry_service),
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
                      setState(() {
                        selectedService = val;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // JUMLAH
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update total
                    },
                  ),

                  const SizedBox(height: 15),

                  // METODE PEMBAYARAN
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
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
                      setState(() {
                        paymentMethod = val!;
                        buktiBayar = null;
                        
                        // 🆕 LOAD PAYMENT INFO SAAT METODE BERUBAH
                        if (val == 'Transfer' || val == 'QRIS') {
                          loadPaymentInfo(val);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🎨 TAMPILKAN INFO PEMBAYARAN
                  if (paymentMethod == 'Transfer')
                    buildTransferInfo(),

                  if (paymentMethod == 'QRIS')
                    buildQrisInfo(),

                  if (paymentMethod == 'Transfer' || paymentMethod == 'QRIS')
                    const SizedBox(height: 20),

                  // UPLOAD BUKTI
                  if (paymentMethod == 'Transfer' || paymentMethod == 'QRIS')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Bukti Pembayaran'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: pickImage,
                        ),
                        if (buktiBayar != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bukti: ${buktiBayar!.name}',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 25),

                  // SUBMIT
                  ElevatedButton(
                    onPressed: submitting ? null : submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        : const Text(
                            'Kirim Pesanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 10),

                  if (message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    jumlahController.dispose();
    super.dispose();
  }
}