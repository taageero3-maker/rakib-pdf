import 'package:flutter/material.dart';

void main() {
  runApp(const RakibPdfApp());
}

class RakibPdfApp extends StatelessWidget {
  const RakibPdfApp({super.key});

  static const Color navy = Color(0xFF10234D);
  static const Color blue = Color(0xFF1769F5);
  static const Color background = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RAKIB PDF',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
          surface: Colors.white,
        ),
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
  int selectedTab = 0;

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — qaybteeda waan ku xidhaynaa tallaabada xigta.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: RakibPdfApp.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            _homeContent(),
            _simplePage('My Documents', Icons.folder_rounded,
                'Dukumentiyadaada PDF halkan ayay ka muuqan doonaan.'),
            _simplePage('Settings', Icons.settings_rounded,
                'Halkan waxaad ka maamuli doontaa dejimaha app-ka.'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F0FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _homeContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3295FF), Color(0xFF0754E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.document_scanner_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RAKIB PDF',
                          style: TextStyle(
                            color: RakibPdfApp.navy,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          )),
                      SizedBox(height: 2),
                      Text('Your documents, simplified',
                          style: TextStyle(
                              color: Color(0xFF7C879B), fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => showComingSoon('Notifications'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: RakibPdfApp.navy,
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  color: RakibPdfApp.navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan, edit and manage your PDF files in one place.',
                style: TextStyle(color: Color(0xFF7C879B), fontSize: 14),
              ),
              const SizedBox(height: 22),
              _scanBanner(),
              const SizedBox(height: 27),
              const Text(
                'PDF Tools',
                style: TextStyle(
                    color: RakibPdfApp.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 13,
                crossAxisSpacing: 13,
                childAspectRatio: 1.48,
                children: [
                  _toolCard(
                    title: 'Images to PDF',
                    subtitle: 'Convert photos',
                    icon: Icons.image_rounded,
                    color: const Color(0xFF20B978),
                    onTap: () => showComingSoon('Images to PDF'),
                  ),
                  _toolCard(
                    title: 'Merge PDF',
                    subtitle: 'Combine files',
                    icon: Icons.call_merge_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => showComingSoon('Merge PDF'),
                  ),
                  _toolCard(
                    title: 'Compress PDF',
                    subtitle: 'Reduce file size',
                    icon: Icons.compress_rounded,
                    color: const Color(0xFFFFA928),
                    onTap: () => showComingSoon('Compress PDF'),
                  ),
                  _toolCard(
                    title: 'Split PDF',
                    subtitle: 'Separate pages',
                    icon: Icons.content_cut_rounded,
                    color: const Color(0xFFEF6477),
                    onTap: () => showComingSoon('Split PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Text('Recent documents',
                      style: TextStyle(
                          color: RakibPdfApp.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => selectedTab = 1),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _recentFile('No documents yet', 'Your scanned PDFs will appear here.',
                  Icons.picture_as_pdf_rounded),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Your files stay on your device',
                  style: TextStyle(color: Color(0xFF9AA4B5), fontSize: 12),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _scanBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF247BFF), Color(0xFF1454DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1769F5).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scan a document',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(
                  'Turn paper into a clear PDF in seconds.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.88), fontSize: 12.5),
                ),
                const SizedBox(height: 17),
                FilledButton.icon(
                  onPressed: () => showComingSoon('Scan Document'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: RakibPdfApp.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 11),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Start scanning',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 92,
            height: 108,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Colors.white, size: 62),
          ),
        ],
      ),
    );
  }

  Widget _toolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: RakibPdfApp.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xFF8994A7), fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentFile(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: RakibPdfApp.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8994A7), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _simplePage(String title, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: RakibPdfApp.blue),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: RakibPdfApp.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7C879B))),
          ],
        ),
      ),
    );
  }
}
