import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'halaman_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

const Color warnaUtama = Color(0xFF17365D);
const Color warnaLatar = Color(0xFFEAF4FF);
const Color warnaTeks = Color(0xFF263238);
const Color warnaSubteks = Color(0xFF7B8490);

const List<String> pilihanWaktu = [
  'Makan Pagi',
  'Makan Siang',
  'Makan Malam',
];

const List<String> pilihanJenis = [
  'Makanan Berat',
  'Camilan',
  'Minuman',
  'Buah',
  'Snack',
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catatan Makanan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: warnaLatar,
        colorScheme: ColorScheme.fromSeed(
          seedColor: warnaUtama,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: warnaUtama,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: warnaUtama,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: warnaUtama, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class HalamanMakanan extends StatefulWidget {
  const HalamanMakanan({super.key});

  @override
  State<HalamanMakanan> createState() => _HalamanMakananState();
}

class _HalamanMakananState extends State<HalamanMakanan> {
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final catatanController = TextEditingController();
  final pencarianController = TextEditingController();

  String? filterWaktu;
  String? filterJenis;
  String kataKunci = '';

  CollectionReference<Map<String, dynamic>> get koleksi {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('catatan_makanan');
  }

  String formatTanggal(DateTime tanggal) {
    return '${tanggal.day.toString().padLeft(2, '0')}/'
        '${tanggal.month.toString().padLeft(2, '0')}/'
        '${tanggal.year}';
  }

  String formatRupiah(int harga) => 'Rp${harga.toString()}';

  void tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> bukaForm({
    DocumentSnapshot<Map<String, dynamic>>? dokumen,
  }) async {
    final data = dokumen?.data();
    String waktuDipilih = pilihanWaktu.contains(data?['waktuMakan'])
        ? data!['waktuMakan'] as String
        : pilihanWaktu[1];
    String jenisDipilih = pilihanJenis.contains(data?['jenisMakanan'])
        ? data!['jenisMakanan'] as String
        : pilihanJenis[0];

    namaController.text = data?['nama'] as String? ?? '';
    hargaController.text = data == null ? '' : '${data['harga'] ?? 0}';
    catatanController.text = data?['catatan'] as String? ?? '';

    // Data baru memakai tanggal hari ini secara otomatis.
    // Saat edit, tanggal lama dipertahankan.
    final tanggalData = data?['tanggal'];

    DateTime tanggalUntukSimpan = tanggalData is Timestamp
        ? tanggalData.toDate()
        : DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: warnaLatar,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                dokumen == null ? 'Tambah Makanan' : 'Edit Makanan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: namaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama makanan',
                          hintText: 'Contoh: Nasi Goreng',
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final tanggalBaru = await showDatePicker(
                            context: context,
                            initialDate: tanggalUntukSimpan,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            helpText: 'Pilih tanggal makanan',
                            cancelText: 'Batal',
                            confirmText: 'Pilih',
                          );

                          if (tanggalBaru != null) {
                            setDialogState(() {
                              tanggalUntukSimpan = tanggalBaru;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: Icon(Icons.calendar_month),
                            suffixIcon: Icon(
                              Icons.edit_calendar,
                              color: warnaUtama,
                            ),
                          ),
                          child: Text(formatTanggal(tanggalUntukSimpan)),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: 5, left: 4),
                          child: Text(
                            'Tekan untuk mengubah tanggal',
                            style: TextStyle(
                              color: warnaSubteks,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: waktuDipilih,
                        decoration: const InputDecoration(
                          labelText: 'Waktu makan',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: pilihanWaktu
                            .map(
                              (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => waktuDipilih = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: jenisDipilih,
                        decoration: const InputDecoration(
                          labelText: 'Jenis makanan',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: pilihanJenis
                            .map(
                              (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => jenisDipilih = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: hargaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          hintText: 'Contoh: 15000',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: catatanController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText: 'Contoh: Makan siang di kampus',
                          prefixIcon: Icon(Icons.notes),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: warnaUtama,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final nama = namaController.text.trim();
                    final harga = int.tryParse(hargaController.text.trim());

                    if (nama.isEmpty || harga == null || harga < 0) {
                      tampilkanPesan('Isi nama dan harga dengan benar.');
                      return;
                    }

                    final catatan = <String, dynamic>{
                      'nama': nama,
                      'tanggal': Timestamp.fromDate(tanggalUntukSimpan),
                      'waktuMakan': waktuDipilih,
                      'jenisMakanan': jenisDipilih,
                      'harga': harga,
                      'catatan': catatanController.text.trim(),
                      'diperbaruiPada': FieldValue.serverTimestamp(),
                    };

                    late Future<void> prosesSimpan;
                    if (dokumen == null) {
                      catatan['dibuatPada'] = FieldValue.serverTimestamp();
                      prosesSimpan = koleksi.add(catatan).then((_) {});
                    } else {
                      prosesSimpan = dokumen.reference.update(catatan);
                    }

                    Navigator.pop(dialogContext);
                    tampilkanPesan(
                      'Data disimpan. Sinkronisasi berjalan jika diperlukan.',
                    );

                    unawaited(
                      prosesSimpan.then((_) {
                        if (mounted) {
                          tampilkanPesan('Data berhasil disinkronkan.');
                        }
                      }).catchError((Object error) {
                        if (mounted) {
                          tampilkanPesan('Sinkronisasi gagal: $error');
                        }
                      }),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    namaController.clear();
    hargaController.clear();
    catatanController.clear();
  }

  Future<void> bukaFilter() async {
    String? waktuSementara = filterWaktu;
    String? jenisSementara = filterJenis;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget pilihanChip({
              required String label,
              required bool terpilih,
              required VoidCallback onTap,
            }) {
              return ChoiceChip(
                label: Text(label),
                selected: terpilih,
                selectedColor: warnaUtama.withValues(alpha: 0.18),
                side: BorderSide(
                  color: terpilih ? warnaUtama : const Color(0xFFE5E7EB),
                ),
                labelStyle: TextStyle(
                  color: terpilih ? warnaUtama : warnaTeks,
                  fontWeight: terpilih ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => onTap(),
              );
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Makanan',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Waktu makan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        pilihanChip(
                          label: 'Semua',
                          terpilih: waktuSementara == null,
                          onTap: () =>
                              setSheetState(() => waktuSementara = null),
                        ),
                        ...pilihanWaktu.map(
                              (waktu) => pilihanChip(
                            label: waktu,
                            terpilih: waktuSementara == waktu,
                            onTap: () => setSheetState(
                                  () => waktuSementara = waktu,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Jenis makanan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        pilihanChip(
                          label: 'Semua',
                          terpilih: jenisSementara == null,
                          onTap: () =>
                              setSheetState(() => jenisSementara = null),
                        ),
                        ...pilihanJenis.map(
                              (jenis) => pilihanChip(
                            label: jenis,
                            terpilih: jenisSementara == jenis,
                            onTap: () => setSheetState(
                                  () => jenisSementara = jenis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: warnaUtama,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          setState(() {
                            filterWaktu = waktuSementara;
                            filterJenis = jenisSementara;
                          });
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Terapkan Filter'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            filterWaktu = null;
                            filterJenis = null;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          'Reset Filter',
                          style: TextStyle(color: warnaUtama),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> hapusMakanan(
      DocumentSnapshot<Map<String, dynamic>> dokumen,
      ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Data makanan ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true) return;

    try {
      await dokumen.reference.delete();
      tampilkanPesan('Catatan berhasil dihapus.');
    } catch (error) {
      tampilkanPesan('Gagal menghapus: $error');
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    hargaController.dispose();
    catatanController.dispose();
    pencarianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jumlahFilterAktif = (filterWaktu == null ? 0 : 1) +
        (filterJenis == null ? 0 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan Makanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Catat makanan hari ini',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: koleksi.orderBy('tanggal', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat catatan:\n${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: warnaUtama),
            );
          }

          final semuaMakanan = snapshot.data?.docs ?? [];
          final makananList = semuaMakanan.where((dokumen) {
            final makanan = dokumen.data();
            final nama = (makanan['nama'] as String? ?? '').toLowerCase();
            final jenis = makanan['jenisMakanan'] as String? ?? '';
            final waktu = makanan['waktuMakan'] as String? ?? '';

            final cocokKata = nama.contains(kataKunci.toLowerCase());
            final cocokWaktu = filterWaktu == null || waktu == filterWaktu;
            final cocokJenis = filterJenis == null || jenis == filterJenis;

            return cocokKata && cocokWaktu && cocokJenis;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: pencarianController,
                  onChanged: (value) => setState(() => kataKunci = value),
                  decoration: InputDecoration(
                    hintText: 'Cari makanan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: kataKunci.isEmpty
                        ? null
                        : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        pencarianController.clear();
                        setState(() => kataKunci = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TombolPilihan(
                        ikon: Icons.schedule,
                        teks: filterWaktu ?? 'Semua Waktu',
                        aktif: filterWaktu != null,
                        onTap: () async {
                          await bukaFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TombolPilihan(
                        ikon: Icons.category_outlined,
                        teks: filterJenis ?? 'Semua Jenis',
                        aktif: filterJenis != null,
                        onTap: () async {
                          await bukaFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Atur filter',
                      onPressed: bukaFilter,
                      icon: Badge(
                        isLabelVisible: jumlahFilterAktif > 0,
                        label: Text('$jumlahFilterAktif'),
                        child: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daftar Makanan',
                        style: TextStyle(
                          color: warnaTeks,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Total: ${makananList.length}',
                      style: const TextStyle(
                        color: warnaSubteks,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: makananList.isEmpty
                    ? _TampilanKosong(
                  adaFilter: kataKunci.isNotEmpty ||
                      filterWaktu != null ||
                      filterJenis != null,
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: makananList.length,
                  itemBuilder: (context, index) {
                    final dokumen = makananList[index];
                    final makanan = dokumen.data();
                    final tanggalData = makanan['tanggal'];
                    final tanggal = tanggalData is Timestamp
                        ? tanggalData.toDate()
                        : DateTime.now();
                    final nama =
                        makanan['nama'] as String? ?? '(Tanpa nama)';
                    final catatan =
                        makanan['catatan'] as String? ?? '';
                    final harga =
                        (makanan['harga'] as num?)?.toInt() ?? 0;
                    final waktu =
                        makanan['waktuMakan'] as String? ?? 'Belum diatur';
                    final jenis =
                        makanan['jenisMakanan'] as String? ?? 'Belum diatur';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEBFA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: warnaUtama,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: warnaTeks,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _LabelKecil(
                                        teks: waktu,
                                        warna: const Color(0xFFDCEBFA),
                                        warnaTeksLabel: const Color(0xFF17365D),
                                      ),
                                      _LabelKecil(
                                        teks: jenis,
                                        warna: const Color(0xFFDCEBFA),
                                        warnaTeksLabel: const Color(0xFF17365D),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      _InfoKecil(
                                        ikon: Icons.calendar_month,
                                        teks: formatTanggal(tanggal),
                                      ),
                                      _InfoKecil(
                                        ikon: Icons.payments_outlined,
                                        teks: formatRupiah(harga),
                                      ),
                                    ],
                                  ),
                                  if (catatan.isNotEmpty) ...[
                                    const SizedBox(height: 7),
                                    Text(
                                      catatan,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: warnaSubteks,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Pilihan makanan',
                              onSelected: (pilihan) {
                                if (pilihan == 'edit') {
                                  bukaForm(dokumen: dokumen);
                                } else if (pilihan == 'hapus') {
                                  hapusMakanan(dokumen);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'hapus',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text('Hapus'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Makanan'),
      ),
    );
  }
}

class _TombolPilihan extends StatelessWidget {
  const _TombolPilihan({
    required this.ikon,
    required this.teks,
    required this.aktif,
    required this.onTap,
  });

  final IconData ikon;
  final String teks;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: aktif ? warnaUtama : warnaTeks,
        side: BorderSide(
          color: aktif ? warnaUtama : const Color(0xFFE8E8E8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              teks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}

class _LabelKecil extends StatelessWidget {
  const _LabelKecil({
    required this.teks,
    required this.warna,
    required this.warnaTeksLabel,
  });

  final String teks;
  final Color warna;
  final Color warnaTeksLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: warnaTeksLabel,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoKecil extends StatelessWidget {
  const _InfoKecil({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 14, color: warnaSubteks),
        const SizedBox(width: 4),
        Text(
          teks,
          style: const TextStyle(color: warnaSubteks, fontSize: 11),
        ),
      ],
    );
  }
}

class _TampilanKosong extends StatelessWidget {
  const _TampilanKosong({required this.adaFilter});

  final bool adaFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: warnaUtama,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              adaFilter ? 'Makanan tidak ditemukan' : 'Belum ada makanan',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: warnaTeks,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              adaFilter
                  ? 'Coba ubah kata pencarian atau reset filter.'
                  : 'Tekan tombol Tambah Makanan untuk mulai mencatat.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: warnaSubteks),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HalamanMakanan();
        }

        return const HalamanLogin();
      },
    );
  }
}
