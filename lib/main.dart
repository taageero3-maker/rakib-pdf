
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RakibPdfApp());
}

const Color primaryBlue = Color(0xFF2878E8);
const Color darkText = Color(0xFF17243A);
const Color lightBackground = Color(0xFFF5F7FB);

class RakibPdfApp extends StatelessWidget {
  const RakibPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAKIB PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// --------------------------------------------------
// HOME SCREEN
// --------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  bool openingScanner = false;

  final List<Map<String, dynamic>> documents = [];

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Directory> getPdfFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/RAKIB_PDF');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return folder;
  }

  Future<void> savePdf(List<Uint8List> pages, String prefix) async {
    if (pages.isEmpty) return;

    final pdf = pw.Document();

    for (final bytes in pages) {
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
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

    final folder = await getPdfFolder();

    final fileName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final file = File('${folder.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;

    setState(() {
      documents.insert(0, {
        'name': fileName,
        'path': file.path,
      });
    });

    showMessage('PDF si guul leh ayaa loo kaydiyey!');
  }

  // CAMERA SCANNER

  Future<void> startScanning() async {
    if (openingScanner) return;

    setState(() {
      openingScanner = true;
    });

    try {
      final pages = await Navigator.push<List<Uint8List>>(
        context,
        MaterialPageRoute(
          builder: (_) => const ScannerScreen(),
        ),
      );

      if (!mounted || pages == null || pages.isEmpty) return;

      final reviewedPages = await Navigator.push<List<Uint8List>>(
        context,
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(pages: pages),
        ),
      );

      if (!mounted ||
          reviewedPages == null ||
          reviewedPages.isEmpty) {
        return;
      }

      await savePdf(reviewedPages, 'RAKIB_SCAN');
    } catch (e) {
      if (mounted) {
        showMessage('Scanner error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          openingScanner = false;
        });
      }
    }
  }

  // IMAGES TO PDF

  Future<void> pickImagesToPdf() async {
    try {
      final picker = ImagePicker();

      final selectedImages = await picker.pickMultiImage();

      if (!mounted || selectedImages.isEmpty) return;

      final List<Uint8List> pages = [];

      for (final image in selectedImages) {
        pages.add(await image.readAsBytes());
      }

      if (!mounted) return;

      final reviewedPages = await Navigator.push<List<Uint8List>>(
        context,
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(pages: pages),
        ),
      );

      if (!mounted ||
          reviewedPages == null ||
          reviewedPages.isEmpty) {
        return;
      }

      await savePdf(reviewedPages, 'RAKIB_IMAGES');
    } catch (e) {
      if (mounted) {
        showMessage('Images error: $e');
      }
    }
  }

  void comingSoon(String name) {
    showMessage('$name dhawaan ayuu imaan doonaa.');
  }

  // HOME PAGE

  Widget homePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: primaryBlue,
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
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Your PDF toolkit',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 2;
                    });
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // SCANNER BANNER

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2878E8),
                    Color(0xFF1554B8),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Scan documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Turn your paper documents into PDF files.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed:
                          openingScanner ? null : startScanning,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        openingScanner ? 'Opening...' : 'Start scanning',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'PDF Tools',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              childAspectRatio: 1.18,
              children: [
                toolCard(
                  Icons.image_outlined,
                  'Images to PDF',
                  const Color(0xFF2878E8),
                  pickImagesToPdf,
                ),
                toolCard(
                  Icons.merge_type,
                  'Merge PDF',
                  const Color(0xFF8B5CF6),
                  () => comingSoon('Merge PDF'),
                ),
                toolCard(
                  Icons.compress,
                  'Compress PDF',
                  const Color(0xFF16A085),
                  () => comingSoon('Compress PDF'),
                ),
                toolCard(
                  Icons.content_cut,
                  'Split PDF',
                  const Color(0xFFEF8B35),
                  () => comingSoon('Split PDF'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                const Text(
                  'Recent Documents',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 1;
                    });
                  },
                  child: const Text('See all'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (documents.isEmpty)
              emptyDocuments()
            else
              ...documents.take(3).map(documentTile),
          ],
        ),
      ),
    );
  }

  Widget toolCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EDF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyDocuments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 38,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            'No documents yet',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Your created PDFs will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget documentTile(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              document['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 19,
          ),
        ],
      ),
    );
  }

  // DOCUMENTS PAGE

  Widget documentsPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Documents',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your recently created PDF files.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: documents.isEmpty
                  ? Center(child: emptyDocuments())
                  : ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        return documentTile(documents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // SETTINGS PAGE

  Widget settingsPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 25),
            settingTile(
              Icons.info_outline,
              'About RAKIB PDF',
              'Version 1.0.0',
            ),
            settingTile(
              Icons.privacy_tip_outlined,
              'Privacy',
              'Your files are stored on your device.',
            ),
            settingTile(
              Icons.help_outline,
              'Help & Support',
              'RAKIB PDF tools',
            ),
          ],
        ),
      ),
    );
  }

  Widget settingTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      documentsPage(),
      settingsPage(),
    ];

    return Scaffold(
      body: pages[selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: primaryBlue.withOpacity(0.12),
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
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// CAMERA SCANNER
// --------------------------------------------------

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  final List<Uint8List> pages = [];

  bool initializing = true;
  bool takingPicture = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found.');
      }

      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (mounted) {
        setState(() {
          initializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          initializing = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> takePicture() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        takingPicture) {
      return;
    }

    setState(() {
      takingPicture = true;
    });

    try {
      final photo = await controller!.takePicture();
      final bytes = await photo.readAsBytes();

      if (!mounted) return;

      setState(() {
        pages.add(bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          takingPicture = false;
        });
      }
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    final currentIndex = cameras.indexOf(controller!.description);
    final nextIndex = (currentIndex + 1) % cameras.length;

    await controller!.dispose();

    controller = CameraController(
      cameras[nextIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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
          if (cameras.length > 1)
            IconButton(
              onPressed: switchCamera,
              icon: const Icon(Icons.flip_camera_android),
            ),
        ],
      ),
      body: initializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: CameraPreview(controller!),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '${pages.length} pages captured',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              if (pages.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      pages.clear();
                                    });
                                  },
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: pages.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(context, pages);
                                      },
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              InkWell(
                                onTap: takePicture,
                                borderRadius: BorderRadius.circular(50),
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
                                          size: 30,
                                        ),
                                ),
                              ),
                              Text(
                                '${pages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// --------------------------------------------------
// SCAN PREVIEW AND PAGE ORDERING
// --------------------------------------------------

class ScanPreviewScreen extends StatefulWidget {
  final List<Uint8List> pages;

  const ScanPreviewScreen({
    super.key,
    required this.pages,
  });

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  late List<Uint8List> pages;

  @override
  void initState() {
    super.initState();
    pages = List<Uint8List>.from(widget.pages);
  }

  void deletePage(int index) {
    setState(() {
      pages.removeAt(index);
    });
  }

  void openFullPreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPagePreview(
          imageBytes: pages[index],
          pageNumber: index + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Preview Pages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: pages.isEmpty
                ? null
                : () {
                    Navigator.pop(context, pages);
                  },
            child: const Text(
              'Create PDF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: pages.isEmpty
          ? const Center(
              child: Text('No pages selected.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${pages.length} pages',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Hold and drag to reorder',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pages.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }

                        final page = pages.removeAt(oldIndex);
                        pages.insert(newIndex, page);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        key: ValueKey(index),
                        margin: const EdgeInsets.only(bottom: 13),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.memory(
                                pages[index],
                                width: 75,
                                height: 95,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Page ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      openFullPreview(index);
                                    },
                                    child: const Text('View page'),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                deletePage(index);
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                            const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: pages.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context, pages);
                            },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Create PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// --------------------------------------------------
// FULL PAGE PREVIEW
// --------------------------------------------------

class FullPagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final int pageNumber;

  const FullPagePreview({
    super.key,
    required this.imageBytes,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Page $pageNumber'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
