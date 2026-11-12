
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RakibPdfApp());
}

class RakibPdfApp extends StatelessWidget {
  const RakibPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RAKIB PDF',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1769E8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  bool openingScanner = false;
  final List<Map<String, dynamic>> documents = [];

  Future<void> startScanning() async {
    if (openingScanner) return;

    setState(() => openingScanner = true);

    try {
      final cameras = await availableCameras();

      if (!mounted) return;

      if (cameras.isEmpty) {
        throw Exception('Telefoonka kamarad lagama helin.');
      }

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerScreen(camera: cameras.first),
        ),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          documents.insert(0, {
            'name': 'Scanned Document ${documents.length + 1}',
            'path': result,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF-ga waa la kaydiyay!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    } finally {
      if (mounted) setState(() => openingScanner = false);
    }
  }

  void comingSoon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name — dhawaan ayuu imanayaa')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: selectedTab == 0
            ? homePage()
            : selectedTab == 1
                ? documentsPage()
                : settingsPage(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFF1769E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RAKIB PDF',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your documents, simplified',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => selectedTab = 2),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF1769E8), Color(0xFF4895F5)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.document_scanner_outlined,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Scan any document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Turn paper documents into high-quality PDFs.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openingScanner ? null : startScanning,
                    icon: openingScanner
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      openingScanner ? 'Opening camera...' : 'Start Scanning',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1769E8),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PDF Tools',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: 1.35,
            children: [
              toolCard(Icons.image_outlined, 'Images to PDF',
                  const Color(0xFF2878E8),
                  () => comingSoon('Images to PDF')),
              toolCard(Icons.merge_type, 'Merge PDF',
                  const Color(0xFF8B5CF6),
                  () => comingSoon('Merge PDF')),
              toolCard(Icons.compress, 'Compress PDF',
                  const Color(0xFF16A085),
                  () => comingSoon('Compress PDF')),
              toolCard(Icons.content_cut, 'Split PDF',
                  const Color(0xFFEF8B35),
                  () => comingSoon('Split PDF')),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Documents',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => selectedTab = 1),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (documents.isEmpty)
            emptyState()
          else
            ...documents.take(3).map(documentTile),
        ],
      ),
    );
  }

  Widget toolCard(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE9EDF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 42, color: Color(0xFF9AA8BA)),
          SizedBox(height: 10),
          Text('No documents yet',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(
            'Your scanned PDFs will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget documentTile(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doc['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget documentsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Documents',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: documents.isEmpty
                ? Center(child: emptyState())
                : ListView(children: documents.map(documentTile).toList()),
          ),
        ],
      ),
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Settings',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.info_outline, color: Color(0xFF1769E8)),
          title: Text('About RAKIB PDF'),
          subtitle: Text('Your all-in-one PDF assistant'),
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip_outlined,
              color: Color(0xFF1769E8)),
          title: Text('Privacy'),
          subtitle: Text('Your documents belong to you'),
        ),
        ListTile(
          leading: Icon(Icons.verified_outlined,
              color: Color(0xFF1769E8)),
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
      ],
    );
  }
}

class ScannerScreen extends StatefulWidget {
  final CameraDescription camera;

  const ScannerScreen({super.key, required this.camera});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController controller;
  late Future<void> initializeController;
  final List<Uint8List> pages = [];
  bool takingPicture = false;
  bool savingPdf = false;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    initializeController = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> capturePage() async {
    if (takingPicture || savingPdf) return;

    setState(() => takingPicture = true);

    try {
      await initializeController;

      if (controller.value.isTakingPicture) return;

      final photo = await controller.takePicture();
      final bytes = await File(photo.path).readAsBytes();

      if (!mounted) return;

      setState(() => pages.add(bytes));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bogga ${pages.length} waa la qaaday')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sawirka lama qaadi karin: $e')),
      );
    } finally {
      if (mounted) setState(() => takingPicture = false);
    }
  }

  Future<void> savePdf() async {
    if (pages.isEmpty || savingPdf) return;

    setState(() => savingPdf = true);

    try {
      final document = pw.Document();

      for (final bytes in pages) {
        final image = pw.MemoryImage(bytes);

        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(18),
            build: (context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/RAKIB_PDF');

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName =
          'RAKIB_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${folder.path}/$fileName');

      await file.writeAsBytes(await document.save());

      if (!mounted) return;

      Navigator.pop(context, file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF lama samayn karin: $e')),
      );
    } finally {
      if (mounted) setState(() => savingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Document Scanner'),
        actions: [
          if (pages.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${pages.length} pages'),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: initializeController,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Camera error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CameraPreview(controller),
                ),
              ),
              if (pages.isNotEmpty)
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 75,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Image.memory(
                            pages[index],
                            width: 55,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: pages.isEmpty
                              ? null
                              : () => setState(() => pages.removeLast()),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        GestureDetector(
                          onTap: takingPicture ? null : capturePage,
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 5,
                              ),
                            ),
                            child: takingPicture
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: pages.isEmpty || savingPdf
                              ? null
                              : savePdf,
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Take photos, then save them as one PDF',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            pages.isEmpty || savingPdf ? null : savePdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1769E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          savingPdf
                              ? 'Creating PDF...'
                              : 'Save PDF (${pages.length} pages)',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
