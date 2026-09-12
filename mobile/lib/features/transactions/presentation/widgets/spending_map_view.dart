import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SpendingLocationItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String dateStr;
  final String address;
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color markerColor;

  const SpendingLocationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateStr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.markerColor,
  });
}

class SpendingMapView extends StatefulWidget {
  final VoidCallback? onBackToList;

  const SpendingMapView({super.key, this.onBackToList});

  @override
  State<SpendingMapView> createState() => _SpendingMapViewState();
}

class _SpendingMapViewState extends State<SpendingMapView> {
  String _selectedCategory = 'ALL';
  SpendingLocationItem? _selectedItem;

  final List<SpendingLocationItem> _allLocations = const [
    SpendingLocationItem(
      id: 'tx_loc_1',
      title: 'Starbucks — ستاربكس',
      category: 'Food',
      amount: 42.75,
      dateStr: 'اليوم، 02:14 م',
      address: 'طريق الأمير محمد بن عبدالعزيز، حي العليا، الرياض',
      latitude: 24.7045,
      longitude: 46.6853,
      icon: Icons.local_cafe_rounded,
      markerColor: Color(0xFF10B981),
    ),
    SpendingLocationItem(
      id: 'tx_loc_2',
      title: 'Uber — أوبر',
      category: 'Transport',
      amount: 35.00,
      dateStr: 'اليوم، 10:32 ص',
      address: 'طريق الملك فهد، حي النموذجية، الرياض',
      latitude: 24.6680,
      longitude: 46.7020,
      icon: Icons.directions_car_filled_rounded,
      markerColor: Color(0xFF3B82F6),
    ),
    SpendingLocationItem(
      id: 'tx_loc_3',
      title: 'أسواق التميمي — Tamimi Markets',
      category: 'Shopping',
      amount: 185.00,
      dateStr: 'أمس، 08:45 م',
      address: 'طريق الأمير تركي الأول، حي حطين، الرياض',
      latitude: 24.7650,
      longitude: 46.6200,
      icon: Icons.shopping_basket_rounded,
      markerColor: Color(0xFFEC4899),
    ),
    SpendingLocationItem(
      id: 'tx_loc_4',
      title: 'محطة شل — Shell Fuel',
      category: 'Transport',
      amount: 78.00,
      dateStr: '08 سبتمبر، 03:15 م',
      address: 'الطريق الدائري الشمالي، حي الملقا، الرياض',
      latitude: 24.7920,
      longitude: 46.6180,
      icon: Icons.local_gas_station_rounded,
      markerColor: Color(0xFFF59E0B),
    ),
    SpendingLocationItem(
      id: 'tx_loc_5',
      title: 'مكتبة جرير — Jarir Bookstore',
      category: 'Shopping',
      amount: 142.50,
      dateStr: '07 سبتمبر، 06:20 م',
      address: 'طريق خريص، حي الروضة، الرياض',
      latitude: 24.7210,
      longitude: 46.7750,
      icon: Icons.menu_book_rounded,
      markerColor: Color(0xFF8B5CF6),
    ),
    SpendingLocationItem(
      id: 'tx_loc_6',
      title: 'مطعم البيك — Al Baik',
      category: 'Food',
      amount: 55.85,
      dateStr: '05 سبتمبر، 09:10 م',
      address: 'شارع الضباب، حي السليمانية، الرياض',
      latitude: 24.6940,
      longitude: 46.7110,
      icon: Icons.restaurant_rounded,
      markerColor: Color(0xFFEF4444),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedItem = _allLocations.first;
  }

  List<SpendingLocationItem> get _filteredLocations {
    if (_selectedCategory == 'ALL') return _allLocations;
    return _allLocations.where((l) => l.category == _selectedCategory).toList();
  }

  double get _totalDisplayedAmount {
    return _filteredLocations.fold(0.0, (sum, i) => sum + i.amount);
  }

  Future<void> _openGoogleMaps(SpendingLocationItem item) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('إحداثيات الموقع: ${item.latitude}, ${item.longitude}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primaryColor = Theme.of(context).primaryColor;

    return Stack(
      children: [
        // 1. Interactive Stylized Map Canvas
        Positioned.fill(
          child: _MapCanvas(
            locations: _filteredLocations,
            selectedItem: _selectedItem,
            isDark: isDark,
            onSelect: (item) {
              setState(() => _selectedItem = item);
            },
          ),
        ),

        // 2. Top Header & Category Filter Bar
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162E22) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E5941) : const Color(0xFFE5DECE),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.22 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.place_rounded, color: Color(0xFF22C55E), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'خريطة أين صرفت؟' : 'Where Did I Spend?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                              ),
                              children: [
                                TextSpan(text: isArabic ? 'إجمالي المعروض: ' : 'Total: '),
                                TextSpan(
                                  text: '${_totalDisplayedAmount.toStringAsFixed(2)} ${isArabic ? "ر.س" : "SAR"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                TextSpan(text: ' (${_filteredLocations.length} ${isArabic ? "مواقع" : "places"})'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onBackToList != null)
                      TextButton.icon(
                        onPressed: widget.onBackToList,
                        icon: const Icon(Icons.list_alt_rounded, size: 16),
                        label: Text(isArabic ? 'القائمة' : 'List', style: const TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips Carousel with High-Contrast Theming
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      key: 'ALL',
                      label: isArabic ? 'الكل' : 'All',
                      icon: Icons.apps_rounded,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      key: 'Food',
                      label: isArabic ? 'مطاعم وكافيهات' : 'Food & Cafes',
                      icon: Icons.restaurant_rounded,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      key: 'Transport',
                      label: isArabic ? 'مواصلات ووقود' : 'Transport',
                      icon: Icons.directions_car_rounded,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      key: 'Shopping',
                      label: isArabic ? 'تسوق ومتاجر' : 'Shopping',
                      icon: Icons.shopping_bag_rounded,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Bottom Selected Transaction Card
        if (_selectedItem != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162E22) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF2E5941) : const Color(0xFFE5DECE),
                  width: 1.4,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedItem!.markerColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedItem!.markerColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(_selectedItem!.icon, color: _selectedItem!.markerColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedItem!.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedItem!.dateStr,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '- ${_selectedItem!.amount.toStringAsFixed(2)} ${isArabic ? "ر.س" : "SAR"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _selectedItem!.markerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF22C55E)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _selectedItem!.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps(_selectedItem!),
                      icon: const Icon(Icons.map_rounded, size: 19),
                      label: Text(
                        isArabic ? 'فتح في خرائط Google' : 'Open in Google Maps',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: const Color(0xFF042116),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
  }) {
    final isSelected = _selectedCategory == key;
    const activeBg = Color(0xFF22C55E);
    const activeText = Color(0xFF042116);
    final inactiveBg = isDark ? const Color(0xFF193325) : Colors.white;
    final inactiveText = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
    final inactiveBorder = isDark ? const Color(0xFF2E5441) : const Color(0xFFD1D5DB);
    final inactiveIcon = isDark ? const Color(0xFF22C55E) : primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeBg : inactiveBorder,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? activeBg.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeText : inactiveIcon,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final List<SpendingLocationItem> locations;
  final SpendingLocationItem? selectedItem;
  final bool isDark;
  final ValueChanged<SpendingLocationItem> onSelect;

  const _MapCanvas({
    required this.locations,
    required this.selectedItem,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(80),
          minScale: 0.8,
          maxScale: 2.5,
          child: SizedBox(
            width: constraints.maxWidth.clamp(360, 1000),
            height: constraints.maxHeight.clamp(500, 1200),
            child: Stack(
              children: [
                // Stylized Vector Map Background
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _StylizedRiyadhMapPainter(isDark: isDark),
                ),

                // Transaction Pins
                ...locations.map((loc) {
                  // Project Saudi/Riyadh coordinates onto relative canvas bounds
                  final xFraction = ((loc.longitude - 46.58) / (46.80 - 46.58)).clamp(0.08, 0.92);
                  final yFraction = (1.0 - ((loc.latitude - 24.64) / (24.82 - 24.64))).clamp(0.12, 0.82);

                  final posX = xFraction * constraints.maxWidth;
                  final posY = yFraction * constraints.maxHeight;
                  final isSelected = selectedItem?.id == loc.id;

                  return Positioned(
                    left: posX - 45,
                    top: posY - 50,
                    child: GestureDetector(
                      onTap: () => onSelect(loc),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price Tag Pill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF22C55E)
                                  : (isDark ? const Color(0xFF1A3326) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Colors.white : loc.markerColor,
                                width: isSelected ? 2.2 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF22C55E).withValues(alpha: 0.45)
                                      : Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                                  blurRadius: isSelected ? 10 : 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${loc.amount.toStringAsFixed(0)} ر.س',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSelected ? 12 : 11,
                                color: isSelected
                                    ? const Color(0xFF042116)
                                    : (isDark ? Colors.white : const Color(0xFF0F261E)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Marker Pin with Icon
                          Container(
                            width: isSelected ? 38 : 30,
                            height: isSelected ? 38 : 30,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF22C55E) : loc.markerColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: isSelected ? 3.0 : 2.2),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSelected ? const Color(0xFF22C55E) : loc.markerColor)
                                      .withValues(alpha: 0.45),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              loc.icon,
                              color: isSelected ? const Color(0xFF042116) : Colors.white,
                              size: isSelected ? 20 : 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StylizedRiyadhMapPainter extends CustomPainter {
  final bool isDark;

  _StylizedRiyadhMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background terrain
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0E1813) : const Color(0xFFF7F5EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks
    final blockPaint = Paint()..color = isDark ? const Color(0xFF182A21) : const Color(0xFFEBE6D8);
    final blockBorder = Paint()
      ..color = isDark ? const Color(0xFF233B2F) : const Color(0xFFDFD8C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 0.05; x < 0.95; x += 0.18) {
      for (double y = 0.1; y < 0.9; y += 0.16) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * x, size.height * y, size.width * 0.13, size.height * 0.11),
          const Radius.circular(10),
        );
        canvas.drawRRect(r, blockPaint);
        canvas.drawRRect(r, blockBorder);
      }
    }

    // 3. Green Parks / Natural zones
    final parkPaint = Paint()..color = isDark ? const Color(0xFF1C422F) : const Color(0xFFD6EACE);
    final parkBorder = Paint()
      ..color = isDark ? const Color(0xFF2F664B) : const Color(0xFFBFDEB2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final park1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.25, size.height * 0.15),
      const Radius.circular(20),
    );
    final park2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.55, size.width * 0.3, size.height * 0.18),
      const Radius.circular(24),
    );
    canvas.drawRRect(park1, parkPaint);
    canvas.drawRRect(park1, parkBorder);
    canvas.drawRRect(park2, parkPaint);
    canvas.drawRRect(park2, parkBorder);

    // 4. Major Highways (King Fahd, Northern Ring) - High-contrast layered roads
    final highwayCasing = Paint()
      ..color = isDark ? const Color(0xFF2B4D3C) : const Color(0xFFD5CEBF)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayFill = Paint()
      ..color = isDark ? const Color(0xFF4C7D63) : Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final primaryRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF335844) : const Color(0xFFEDE9DF)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    // King Fahd Highway (Vertical)
    final h1 = Path();
    h1.moveTo(size.width * 0.45, 0);
    h1.lineTo(size.width * 0.48, size.height);
    canvas.drawPath(h1, highwayCasing);
    canvas.drawPath(h1, highwayFill);

    // Northern Ring Road (Horizontal)
    final h2 = Path();
    h2.moveTo(0, size.height * 0.35);
    h2.lineTo(size.width, size.height * 0.32);
    canvas.drawPath(h2, highwayCasing);
    canvas.drawPath(h2, highwayFill);

    // Olaya St & Makkah Rd
    final r1 = Path();
    r1.moveTo(size.width * 0.62, 0);
    r1.lineTo(size.width * 0.65, size.height);
    canvas.drawPath(r1, primaryRoadPaint);

    final r2 = Path();
    r2.moveTo(0, size.height * 0.7);
    r2.lineTo(size.width, size.height * 0.65);
    canvas.drawPath(r2, primaryRoadPaint);

    // Diagonal arterial
    final r3 = Path();
    r3.moveTo(0, size.height * 0.15);
    r3.lineTo(size.width * 0.9, size.height * 0.9);
    canvas.drawPath(r3, primaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
