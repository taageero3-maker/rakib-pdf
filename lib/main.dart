
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

void main() {
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
        fontFamily: 'Roboto',
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
  bool scanning = false;
  int selectedTab = 0;
  final List<Map<String, dynamic>> documents = [];

  Future<void> startScanning() async {
    if (scanning) return;

    setState(() => scanning = true);

    try {
      final result =
          await FlutterDocScanner().getScannedDocumentAsPdf(page: 10);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          documents.insert(0, {
            'name': 'Scanned Document ${documents.length + 1}',
            'pages': result.pageCount,
            'path': result.pdfUri,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF-ga waa la sameeyay!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanner error: $e')),
      );
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — dhawaan ayuu imanayaa')),
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
                onPressed: () => selectedTab = 2,
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
                    onPressed: scanning ? null : startScanning,
                    icon: scanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      scanning ? 'Opening scanner...' : 'Start Scanning',
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
                  () => showComingSoon('Images to PDF')),
              toolCard(Icons.merge_type, 'Merge PDF',
                  const Color(0xFF8B5CF6),
                  () => showComingSoon('Merge PDF')),
              toolCard(Icons.compress, 'Compress PDF',
                  const Color(0xFF16A085),
                  () => showComingSoon('Compress PDF')),
              toolCard(Icons.content_cut, 'Split PDF',
                  const Color(0xFFEF8B35),
                  () => showComingSoon('Split PDF')),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${doc['pages']} pages',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const ListTile(
          leading: Icon(Icons.info_outline, color: Color(0xFF1769E8)),
          title: Text('About RAKIB PDF'),
          subtitle: Text('Your all-in-one PDF assistant'),
        ),
        const ListTile(
          leading: Icon(Icons.privacy_tip_outlined,
              color: Color(0xFF1769E8)),
          title: Text('Privacy'),
          subtitle: Text('Your documents belong to you'),
        ),
        const ListTile(
          leading: Icon(Icons.verified_outlined,
              color: Color(0xFF1769E8)),
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
      ],
    );
  }
}
