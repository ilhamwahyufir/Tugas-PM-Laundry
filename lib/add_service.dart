import 'package:flutter/material.dart';
import 'api_service.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final satuanController = TextEditingController();
  String message = '';

  void saveService() async {
    final res = await ApiService.addService(
      namaController.text,
      hargaController.text,
      satuanController.text,
    );

    setState(() {
      message = res['message'] ?? '';
    });

    if (res['message'] == 'Layanan berhasil ditambahkan') {
      Navigator.pop(context, true); // balik & refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Layanan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration:
                  const InputDecoration(labelText: 'Nama Layanan'),
            ),
            TextField(
              controller: hargaController,
              decoration: const InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: satuanController,
              decoration:
                  const InputDecoration(labelText: 'Satuan (kg / pcs)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveService,
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 10),
            Text(message),
          ],
        ),
      ),
    );
  }
}
