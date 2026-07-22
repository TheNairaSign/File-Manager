import 'package:file_manager/core/platform/file_channel.dart';
import 'package:file_manager/features/operations/presentation/widgets/stotage_info_container.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() { 
    super.initState();
    getStorageInfo();
  }

  void getStorageInfo() {
    FileChannel().getStorageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.search, size: 28, color: Color(0xFF2D3142)),
                onPressed: () {},
              ),
              const SizedBox(height: 24),

              // Categories Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildCategoryItem("Docs", Icons.description, const Color(0xFFFFF9E6), const Color(0xFFFFB300)),
                  _buildCategoryItem("Images", Icons.image, const Color(0xFFFFEAEA), const Color(0xFFFF5252)),
                  _buildCategoryItem("Videos", Icons.videocam, const Color(0xFFEBE8FF), const Color(0xFF7C4DFF)),
                  _buildCategoryItem("Music", Icons.music_note, const Color(0xFFE8F8EE), const Color(0xFF00E676)),
                  _buildCategoryItem("Archieves", Icons.inventory_2, const Color(0xFFE3F2FD), const Color(0xFF2196F3)),
                  _buildCategoryItem("APKs", Icons.android, const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
                  _buildCategoryItem("Shared", Icons.swap_vert, const Color(0xFFE1F5FE), const Color(0xFF03A9F4)),
                  _buildCategoryItem("More", Icons.apps, const Color(0xFFECEFF1), const Color(0xFF607D8B)),
                ],
              ),
              const SizedBox(height: 28),

              // Cleaner and Safe Folder Rows
              _buildListRow("Cleaner", Icons.brush, const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
              const SizedBox(height: 12),
              _buildListRow("Safe Folder", Icons.lock_outline, const Color(0xFFEBE8FF), const Color(0xFF7C4DFF)),
              const SizedBox(height: 28),

              // Storage Info Animated Card
              FutureBuilder(
                future: FileChannel().getStorageInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error loading storage: ${snapshot.error}"),
                    );
                  }
                  if (snapshot.hasData) {
                    return StorageInfoContainer(storageInfo: snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color bgColor, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(String label, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}