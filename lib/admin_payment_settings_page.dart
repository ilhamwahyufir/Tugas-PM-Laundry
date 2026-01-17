import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class AdminPaymentSettingsPage extends StatefulWidget {
  const AdminPaymentSettingsPage({super.key});

  @override
  State<AdminPaymentSettingsPage> createState() => _AdminPaymentSettingsPageState();
}

class _AdminPaymentSettingsPageState extends State<AdminPaymentSettingsPage> {
  List<dynamic> paymentSettings = [];
  bool loading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadPaymentSettings();
  }

  Future<void> loadPaymentSettings() async {
    try {
      final data = await ApiService.getAllPaymentSettings();
      setState(() {
        paymentSettings = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        message = 'Gagal memuat data: $e';
      });
    }
  }

  Future<void> deletePaymentSetting(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus payment setting ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.deletePaymentSetting(id);

    if (mounted) {
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
            content: Text('Payment setting berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        loadPaymentSettings();
      }
    }
  }

  void showAddBankDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final holderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Rekening Bank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bank',
                  hintText: 'Contoh: BCA, Mandiri',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderController,
                decoration: const InputDecoration(
                  labelText: 'Atas Nama',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  numberController.text.isEmpty ||
                  holderController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua field harus diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await ApiService.addPaymentSetting(
                'Transfer',
                nameController.text,
                numberController.text,
                holderController.text,
              );

              if (mounted) {
                Navigator.pop(context);

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
                      content: Text('Rekening bank berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  loadPaymentSettings();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void showEditBankDialog(dynamic bank) {
    final nameController = TextEditingController(text: bank['bank_name']);
    final numberController = TextEditingController(text: bank['account_number']);
    final holderController = TextEditingController(text: bank['account_holder']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Rekening Bank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bank',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderController,
                decoration: const InputDecoration(
                  labelText: 'Atas Nama',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  numberController.text.isEmpty ||
                  holderController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua field harus diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await ApiService.updatePaymentSetting(
                bank['id'],
                'Transfer',
                nameController.text,
                numberController.text,
                holderController.text,
              );

              if (mounted) {
                Navigator.pop(context);

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
                      content: Text('Rekening bank berhasil diupdate'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  loadPaymentSettings();
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> uploadQrisImage(int paymentSettingId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final result = await ApiService.uploadQrisImage(paymentSettingId, picked);

    if (mounted) {
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
            content: Text('QRIS berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
        loadPaymentSettings();
      }
    }
  }

  Future<void> addQrisPayment() async {
    final result = await ApiService.addPaymentSetting(
      'QRIS',
      null,
      null,
      null,
    );

    if (mounted) {
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
            content: Text('QRIS berhasil ditambahkan. Silakan upload gambar QR Code.'),
            backgroundColor: Colors.green,
          ),
        );
        loadPaymentSettings();
      }
    }
  }

  Widget buildBankCard(dynamic bank) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white),
          ),
          title: Text(
            bank['bank_name'] ?? 'Bank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'No. Rek: ${bank['account_number'] ?? '-'}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'A/N: ${bank['account_holder'] ?? '-'}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => showEditBankDialog(bank),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deletePaymentSetting(bank['id']),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQrisCard(dynamic qris) {
    final qrisImage = qris['qris_image'];
    final qrisUrl = qrisImage != null
        ? 'http://localhost:3000/uploads/$qrisImage'
        : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'QRIS Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deletePaymentSetting(qris['id']),
                  tooltip: 'Hapus',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (qrisUrl != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  qrisUrl,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('Gambar tidak tersedia'),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('QR Code belum diupload'),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(qrisUrl != null ? 'Ganti QR Code' : 'Upload QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
              ),
              onPressed: () => uploadQrisImage(qris['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banks = paymentSettings.where((p) => p['payment_type'] == 'Transfer').toList();
    final qrisList = paymentSettings.where((p) => p['payment_type'] == 'QRIS').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Metode Pembayaran'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadPaymentSettings,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // SECTION: REKENING BANK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rekening Bank',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Bank'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: showAddBankDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (banks.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada rekening bank',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: showAddBankDialog,
                              child: const Text('Tambah Rekening'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...banks.map(buildBankCard),

                  const SizedBox(height: 30),

                  // SECTION: QRIS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QRIS Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (qrisList.isEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah QRIS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: addQrisPayment,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (qrisList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada QRIS',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: addQrisPayment,
                              child: const Text('Tambah QRIS'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...qrisList.map(buildQrisCard),

                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}