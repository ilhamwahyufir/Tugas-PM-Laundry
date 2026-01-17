import 'package:flutter/material.dart';
import 'api_service.dart';

class EditServicePage extends StatefulWidget {
  const EditServicePage({super.key});

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  List services = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  // ========================
  // LOAD SERVICES
  // ========================
  Future<void> loadServices() async {
    setState(() {
      loading = true;
    });

    try {
      final data = await ApiService.getServices();
      setState(() {
        services = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat layanan: $e')),
        );
      }
    }
  }

  // ========================
  // SHOW ADD/EDIT DIALOG
  // ========================
  void showServiceDialog({Map? service}) {
    final isEdit = service != null;
    final namaController = TextEditingController(text: service?['nama'] ?? '');
    final hargaController = TextEditingController(text: service?['harga']?.toString() ?? '');
    final satuanController = TextEditingController(text: service?['satuan'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Layanan' : 'Tambah Layanan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Layanan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: satuanController,
                decoration: const InputDecoration(
                  labelText: 'Satuan (kg, pcs, dll)',
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
              if (namaController.text.isEmpty ||
                  hargaController.text.isEmpty ||
                  satuanController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field wajib diisi')),
                );
                return;
              }

              Navigator.pop(context);

              if (isEdit) {
                await updateService(
                  service['id'],
                  namaController.text,
                  hargaController.text,
                  satuanController.text,
                );
              } else {
                await addService(
                  namaController.text,
                  hargaController.text,
                  satuanController.text,
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  // ========================
  // ADD SERVICE
  // ========================
  Future<void> addService(String nama, String harga, String satuan) async {
    try {
      final res = await ApiService.addService(nama, harga, satuan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Layanan berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      loadServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah layanan: $e')),
        );
      }
    }
  }

  // ========================
  // UPDATE SERVICE
  // ========================
  Future<void> updateService(int id, String nama, String harga, String satuan) async {
    try {
      final res = await ApiService.updateService(id, nama, harga, satuan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Layanan berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      loadServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update layanan: $e')),
        );
      }
    }
  }

  // ========================
  // DELETE SERVICE
  // ========================
  Future<void> deleteService(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus layanan "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.deleteService(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Layanan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        loadServices();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus layanan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Layanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadServices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada layanan',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Layanan Pertama'),
                        onPressed: () => showServiceDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          service['nama'] ?? '-',
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
                              'Rp ${service['harga']} / ${service['satuan']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => showServiceDialog(service: service),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus',
                              onPressed: () => deleteService(
                                service['id'],
                                service['nama'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
      ),
    );
  }
}