
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:document_scan/document_scan.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_document/pdf_document.dart' as pdfdoc;
import 'package:file_compression_plus/file_compression_plus.dart';

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
  @override
void initState() {
  super.initState();
  loadDocuments();
}

Future<void> loadDocuments() async {
  try {
    final folder = await getPdfFolder();

    final files = await folder
        .list()
        .where(
          (file) =>
              file is File &&
              file.path.toLowerCase().endsWith('.pdf'),
        )
        .cast<File>()
        .toList();

    files.sort(
      (a, b) => b.lastModifiedSync().compareTo(
        a.lastModifiedSync(),
      ),
    );

    final loadedDocuments = files.map((file) {
      return {
        'name': file.uri.pathSegments.last,
        'path': file.path,
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      documents
        ..clear()
        ..addAll(loadedDocuments);
    });
  } catch (e) {
    debugPrint('Loading documents error: $e');
  }
}
  
Future<void> mergePdfFiles() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.length < 2) {
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least 2 PDF files'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merging PDFs...')),
    );

    final List<Uint8List> pdfBytes = [];

    for (final selectedFile in result.files) {
      Uint8List? bytes = selectedFile.bytes;

      if (bytes == null && selectedFile.path != null) {
        bytes = await File(selectedFile.path!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Could not read ${selectedFile.name}');
      }

      pdfBytes.add(bytes);
    }

    final mergedBytes = pdfdoc.PdfMerger.merge(pdfBytes);

    final folder = await getPdfFolder();

    final fileName =
        'Merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final outputFile = File('${folder.path}/$fileName');

    await outputFile.writeAsBytes(mergedBytes);

    if (!mounted) return;

    setState(() {
      documents.insert(0, {
        'name': fileName,
        'path': outputFile.path,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDFs merged successfully!'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Merge failed: $e')),
    );
  }
}

Future<void> splitPdfFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null) return;

    final selectedFile = result.files.single;

    Uint8List? bytes = selectedFile.bytes;

    if (bytes == null && selectedFile.path != null) {
      bytes = await File(selectedFile.path!).readAsBytes();
    }

    if (bytes == null) {
      throw Exception('Could not read PDF file');
    }

    final pdfDocument = pdfdoc.PdfDocument.open(bytes);
    final pageCount = pdfDocument.pageCount;

    if (!mounted) return;

    final controller = TextEditingController();

    final expression = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Split PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This PDF has $pageCount pages.'),
              const SizedBox(height: 12),
              const Text(
                'Enter page ranges. Each comma creates a separate PDF.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Example: 1-3, 4-6',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Split'),
            ),
          ],
        );
      },
    );
    Future<void> compressPdfFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null) return;

    final selectedFile = result.files.single;

    File? inputFile;

    if (selectedFile.path != null) {
      inputFile = File(selectedFile.path!);
    } else if (selectedFile.bytes != null) {
      final tempDir = await getTemporaryDirectory();
      inputFile = File(
        '${tempDir.path}/compress_input_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await inputFile.writeAsBytes(selectedFile.bytes!);
    }

    if (inputFile == null) {
      throw Exception('Could not read PDF file');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compressing PDF...')),
    );

    final folder = await getPdfFolder();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Compressed_$stamp.pdf';
    final outputPath = '${folder.path}/$fileName';

    final compression = await FileCompressor.compressPdfWithResult(
      file: inputFile,
      compressionLevel: PdfCompressionLevel.best,
      removeMetadata: true,
      outputPath: outputPath,
      skipIfLarger: true,
      deleteOriginal: false,
    );

    if (!mounted) return;

    setState(() {
      documents.insert(0, {
        'name': fileName,
        'path': compression.file.path,
      });
    });

    final message = compression.wasSkipped
        ? 'PDF was already small. Original size: ${formatBytes(compression.originalSize)}'
        : 'Compressed: ${formatBytes(compression.originalSize)} → ${formatBytes(compression.compressedSize)} (${compression.savedPercentage.toStringAsFixed(1)}% saved)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compression failed: $e')),
    );
  }
}
    
    controller.dispose();

    if (expression == null || expression.isEmpty) return;

    final parts = pdfdoc.PdfSplitter.splitExpression(
      bytes,
      expression,
    );

    final folder = await getPdfFolder();

    final stamp = DateTime.now().millisecondsSinceEpoch;

    final newDocuments = <Map<String, dynamic>>[];

    for (int i = 0; i < parts.length; i++) {
      final fileName = 'Split_${stamp}_${i + 1}.pdf';

      final outputFile = File('${folder.path}/$fileName');

      await outputFile.writeAsBytes(parts[i]);

      newDocuments.add({
        'name': fileName,
        'path': outputFile.path,
      });
    }

    if (!mounted) return;

    setState(() {
      documents.insertAll(0, newDocuments);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${parts.length} PDF files created successfully!'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split failed: $e')),
    );
  }
}

  
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
      mergePdfFiles,
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
      splitPdfFile,
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
  final String filePath = document['path'] as String;
  final String fileName = document['name'] as String;

  Future<void> renameDocument() async {
    final controller = TextEditingController(
      text: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename PDF'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New document name',
              hintText: 'Enter a name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty) return;

    final cleanName = newName.trim().replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    final finalName = cleanName.toLowerCase().endsWith('.pdf')
        ? cleanName
        : '$cleanName.pdf';

    final oldFile = File(filePath);
    final newPath = '${oldFile.parent.path}/$finalName';

    if (newPath == filePath) return;

    try {
      if (await File(newPath).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A file with this name already exists.')),
        );
        return;
      }

      await oldFile.rename(newPath);

      if (!mounted) return;

      setState(() {
        document['name'] = finalName;
        document['path'] = newPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF renamed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rename failed: $e')),
      );
    }
  }

  Future<void> deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete PDF?'),
          content: Text('Are you sure you want to delete "$fileName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      if (!mounted) return;

      setState(() {
        documents.removeWhere(
          (item) => item['path'] == filePath,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> shareDocument() async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found');
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: fileName,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  return InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: filePath,
            title: fileName,
          ),
        ),
      );
    },
    child: Container(
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
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
            onSelected: (value) {
              if (value == 'rename') {
                renameDocument();
              } else if (value == 'share') {
                shareDocument();
              } else if (value == 'delete') {
                deleteDocument();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
  Future<void> editPage(int index) async {
  final editedImage = await Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      builder: (_) => ScanEditorScreen(
        imageBytes: pages[index],
      ),
    ),
  );

  if (editedImage != null && mounted) {
    setState(() {
      pages[index] = editedImage;
    });
  }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          openFullPreview(index);
                        },
                        child: const Text('View page'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          editPage(index);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ],
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
// --------------------------------------------------
// SCAN EDITOR
// --------------------------------------------------

class ScanEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ScanEditorScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<ScanEditorScreen> createState() => _ScanEditorScreenState();
}

class _ScanEditorScreenState extends State<ScanEditorScreen> {
  late Uint8List originalBytes;

  ui.Image? decodedImage;
  DocumentCorners? corners;

  bool loading = true;
  bool processing = false;

  ScanFilter selectedFilter = ScanFilter.none;

  String? errorMessage;
  int selectedCorner = -1;

  final List<ScanFilter> filters = [
    ScanFilter.none,
    ScanFilter.grayscale,
    ScanFilter.enhance,
    ScanFilter.blackWhite,
    ScanFilter.sharpen,
  ];

  final List<String> filterNames = [
    'Original',
    'Grayscale',
    'Enhance',
    'Black & White',
    'Sharpen',
  ];

  @override
  void initState() {
    super.initState();
    originalBytes = widget.imageBytes;
    loadImage();
  }

  Future<void> loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();

      decodedImage = frame.image;

      final detector = DocumentDetector();

      final detectedCorners = await detector.detect(
        ScanInput.bytes(
          originalBytes,
          width: decodedImage!.width,
          height: decodedImage!.height,
        ),
        sensitivity: DetectionSensitivity.lenient,
      );

      if (!mounted) return;

      setState(() {
        corners = detectedCorners ??
            const DocumentCorners(
              topLeft: (x: 0.01, y: 0.01),
              topRight: (x: 0.99, y: 0.01),
              bottomRight: (x: 0.99, y: 0.99),
              bottomLeft: (x: 0.01, y: 0.99),
            );

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<Offset> get cornerPositions {
    if (corners == null) return [];

    return [
      Offset(corners!.topLeft.x, corners!.topLeft.y),
      Offset(corners!.topRight.x, corners!.topRight.y),
      Offset(corners!.bottomRight.x, corners!.bottomRight.y),
      Offset(corners!.bottomLeft.x, corners!.bottomLeft.y),
    ];
  }

  void updateCorner(Offset position) {
    if (corners == null || decodedImage == null) return;

    final x = position.dx.clamp(0.0, 1.0);
    final y = position.dy.clamp(0.0, 1.0);

    setState(() {
      switch (selectedCorner) {
        case 0:
          corners = corners!.copyWith(
            topLeft: (x: x, y: y),
          );
          break;

        case 1:
          corners = corners!.copyWith(
            topRight: (x: x, y: y),
          );
          break;

        case 2:
          corners = corners!.copyWith(
            bottomRight: (x: x, y: y),
          );
          break;

        case 3:
          corners = corners!.copyWith(
            bottomLeft: (x: x, y: y),
          );
          break;
      }
    });
  }

  void startDragging(Offset position, Size size) {
    if (corners == null) return;

    final normalized = Offset(
      (position.dx / size.width).clamp(0.0, 1.0),
      (position.dy / size.height).clamp(0.0, 1.0),
    );

    double nearestDistance = double.infinity;
    int nearestIndex = -1;

    for (int i = 0; i < cornerPositions.length; i++) {
      final distance =
          (cornerPositions[i] - normalized).distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    if (nearestDistance < 0.15) {
      selectedCorner = nearestIndex;
      updateCorner(normalized);
    }
  }

  void dragCorner(Offset position, Size size) {
    if (selectedCorner == -1) return;

    final normalized = Offset(
      (position.dx / size.width).clamp(0.0, 1.0),
      (position.dy / size.height).clamp(0.0, 1.0),
    );

    updateCorner(normalized);
  }
  
Future<void> rotateImage() async {
  if (processing || loading || decodedImage == null) return;

  setState(() {
    processing = true;
  });

  try {
    final image = decodedImage!;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.translate(image.height.toDouble(), 0);
    canvas.rotate(math.pi / 2);

    canvas.drawImage(
      image,
      Offset.zero,
      Paint(),
    );

    final picture = recorder.endRecording();

    final rotatedImage = await picture.toImage(
      image.height,
      image.width,
    );

    final byteData = await rotatedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Could not rotate image.');
    }

    final rotatedBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    final detector = DocumentDetector();

    final detectedCorners = await detector.detect(
      ScanInput.bytes(
        rotatedBytes,
        width: rotatedImage.width,
        height: rotatedImage.height,
      ),
      sensitivity: DetectionSensitivity.lenient,
    );

    if (!mounted) return;

    setState(() {
      originalBytes = rotatedBytes;
      decodedImage = rotatedImage;

      corners = detectedCorners ??
          const DocumentCorners(
            topLeft: (x: 0.01, y: 0.01),
            topRight: (x: 0.99, y: 0.01),
            bottomRight: (x: 0.99, y: 0.99),
            bottomLeft: (x: 0.01, y: 0.99),
          );

      selectedCorner = -1;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rotate error: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        processing = false;
      });
    }
  }
}

  Future<void> applyCrop() async {
    if (corners == null || processing) return;

    setState(() {
      processing = true;
    });

    try {
      final input = ScanInput.bytes(
        originalBytes,
        width: decodedImage!.width,
        height: decodedImage!.height,
      );

      final processor = const DocumentProcessor();

      final result = await processor.crop(
  input,
  corners!,
  filter: selectedFilter,
  output: ScanOutputFormat.png,
  background: true,
);

if (!mounted) return;

if (result == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Crop failed. Please try again.'),
    ),
  );
  return;
}

Navigator.pop(context, result.bytes); 

    
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Crop error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
  title: const Text(
    'Edit Document',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  backgroundColor: Colors.white,
  actions: [
    IconButton(
      onPressed: processing || loading ? null : rotateImage,
      tooltip: 'Rotate 90°',
      icon: const Icon(Icons.rotate_right),
    ),
  ],
),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(errorMessage!),
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Drag the four corners to adjust the document.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: decodedImage!.width /
                              decodedImage!.height,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );

                              return GestureDetector(
                                onPanStart: (details) {
                                  startDragging(
                                    details.localPosition,
                                    size,
                                  );
                                },
                                onPanUpdate: (details) {
                                  dragCorner(
                                    details.localPosition,
                                    size,
                                  );
                                },
                                onPanEnd: (_) {
                                  selectedCorner = -1;
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      originalBytes,
                                      fit: BoxFit.fill,
                                    ),
                                    CustomPaint(
                                      painter: DocumentCornersPainter(
                                        positions: cornerPositions,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: filters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return ChoiceChip(
                                  label: Text(filterNames[index]),
                                  selected:
                                      selectedFilter == filters[index],
                                  onSelected: (_) {
                                    setState(() {
                                      selectedFilter = filters[index];
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed:
                                  processing ? null : applyCrop,
                              icon: processing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.crop),
                              label: Text(
                                processing
                                    ? 'Processing...'
                                    : 'Apply Crop',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
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
// DOCUMENT CORNERS PAINTER
// --------------------------------------------------

class DocumentCornersPainter extends CustomPainter {
  final List<Offset> positions;

  DocumentCornersPainter({
    required this.positions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length != 4) return;

    final points = positions.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas.drawPath(path, linePaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 10, handlePaint);
      canvas.drawCircle(point, 10, borderPaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant DocumentCornersPainter oldDelegate,
  ) {
    return oldDelegate.positions != positions;
  }
}
// --------------------------------------------------
// PDF VIEWER
// --------------------------------------------------

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? totalPages;
  int currentPage = 1;
  bool isReady = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (totalPages != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            backgroundColor: const Color(0xFFE9EDF4),
            fitPolicy: FitPolicy.WIDTH,
            onRender: (pages) {
              if (!mounted) return;

              setState(() {
                totalPages = pages;
                isReady = true;
              });
            },
            onPageChanged: (page, total) {
              if (!mounted) return;

              setState(() {
                currentPage = (page ?? 0) + 1;
totalPages = total;
              });
            },
            onError: (error) {
              if (!mounted) return;

              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              if (!mounted) return;

              setState(() {
                errorMessage = 'Page ${(page ?? 0) + 1}: $error';
              });
            },
          ),

          if (!isReady && errorMessage == null)
            const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            ),

          if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'PDF could not be opened:\n$errorMessage',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

