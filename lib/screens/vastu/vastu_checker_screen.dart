import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/vastu_rules.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/vastu_compass_dial.dart';

class VastuCheckerScreen extends StatefulWidget {
  const VastuCheckerScreen({super.key});

  @override
  State<VastuCheckerScreen> createState() => _VastuCheckerScreenState();
}

class _VastuCheckerScreenState extends State<VastuCheckerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VastuDirection _selectedCompassDirection = VastuDirection.northEast;

  // Selected room placements for the House Auditor
  final Map<String, VastuDirection> _roomPlacements = {
    'kitchen': VastuDirection.southEast,
    'master_bedroom': VastuDirection.southWest,
    'puja_room': VastuDirection.northEast,
    'toilet': VastuDirection.northWest,
    'living_room': VastuDirection.northEast,
    'staircase': VastuDirection.southWest,
    'main_door': VastuDirection.northEast,
    'water_tank': VastuDirection.southWest,
    'underground_sump': VastuDirection.northEast,
  };

  VastuDirection _houseFacing = VastuDirection.east;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareAuditReport(Map<String, dynamic> audit) {
    final buffer = StringBuffer();
    buffer.writeln('🏛️ BuildCalc - House Plan Vastu Audit Report');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('Overall Vastu Score: ${audit['score']}% (${audit['ratingText']})');
    buffer.writeln('Main House Facing: ${_houseFacing.shortName}');
    buffer.writeln('────────────────────────────────────────');

    final results = audit['results'] as List<Map<String, dynamic>>;
    for (final res in results) {
      final RoomVastuRule rule = res['rule'];
      final VastuDirection dir = res['direction'];
      final VastuSuitability suit = res['suitability'];

      String emoji = '✅';
      if (suit == VastuSuitability.defect) emoji = '❌';
      if (suit == VastuSuitability.average) emoji = '⚠️';

      buffer.writeln('$emoji ${rule.roomName}: ${dir.shortName} - ${suit.label}');
      if (suit == VastuSuitability.defect) {
        buffer.writeln('   Remedy: ${rule.remedy}');
      }
    }

    buffer.writeln('\nAudited with BuildCalc (Free Construction & 3D Plan App)');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc');

    Share.share(buffer.toString(), subject: 'BuildCalc Vastu Audit Report');
    AdService.showInterstitialAfterCalculation();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vastu Shastra & Room Checker'),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8C00),
          labelColor: const Color(0xFFFF8C00),
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.explore_rounded), text: 'Compass'),
            Tab(icon: Icon(Icons.checklist_rtl_rounded), text: 'Plan Auditor'),
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Guide & Tips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompassTab(isDark),
          _buildAuditorTab(isDark),
          _buildGuideTab(isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: INTERACTIVE COMPASS & DIRECTION ZONE GUIDE
  // ---------------------------------------------------------------------------
  Widget _buildCompassTab(bool isDark) {
    final dir = _selectedCompassDirection;

    // Find all rooms suitable or defective for this direction
    final recommendedRooms = VastuKnowledgeBase.roomRules.where((r) {
      final suit = r.suitability[dir];
      return suit == VastuSuitability.excellent || suit == VastuSuitability.good;
    }).toList();

    final defectiveRooms = VastuKnowledgeBase.roomRules.where((r) {
      final suit = r.suitability[dir];
      return suit == VastuSuitability.defect;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF1E3A5F),
                    size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Rotate the dial or tap any direction below to inspect Vedic ruling deities, elements, and ideal room placements.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Custom Dial
          VastuCompassDial(
            selectedDirection: _selectedCompassDirection,
            onDirectionChanged: (newDir) {
              setState(() => _selectedCompassDirection = newDir);
            },
          ),
          const SizedBox(height: 16),

          // Quick Direction Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                VastuDirection.north,
                VastuDirection.northEast,
                VastuDirection.east,
                VastuDirection.southEast,
                VastuDirection.south,
                VastuDirection.southWest,
                VastuDirection.west,
                VastuDirection.northWest,
              ].map((d) {
                final isSelected = d == _selectedCompassDirection;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d.shortName, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    selectedColor: d.elementColor.withValues(alpha: 0.25),
                    side: BorderSide(
                      color: isSelected ? d.elementColor : Colors.grey.shade300,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedCompassDirection = d);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Direction Deep Dive Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: dir.elementColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: dir.elementColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dir.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: dir.elementColor,
                          ),
                        ),
                        Text(
                          'Deity: ${dir.sanskritName} • ${dir.degreeAngle.toInt()}°',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: dir.elementColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dir.element,
                        style: TextStyle(
                          color: dir.elementColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Ideal Placements
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Ideal / Recommended Rooms',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recommendedRooms.isEmpty)
                  const Text('No primary living rooms recommended here.',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: recommendedRooms.map((r) {
                      return Chip(
                        avatar: Icon(r.icon, size: 14, color: const Color(0xFF16A34A)),
                        label: Text(r.roomName, style: const TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 14),

                // Incompatible Placements
                const Row(
                  children: [
                    Icon(Icons.cancel_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Strictly Avoid (Doshas)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (defectiveRooms.isEmpty)
                  const Text('None — this direction is universally neutral or safe.',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: defectiveRooms.map((r) {
                      return Chip(
                        avatar: Icon(r.icon, size: 14, color: const Color(0xFFDC2626)),
                        label: Text(r.roomName, style: const TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppBannerAd(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: HOUSE PLAN ROOM AUDITOR & COMPLIANCE SCORE
  // ---------------------------------------------------------------------------
  Widget _buildAuditorTab(bool isDark) {
    final audit = VastuKnowledgeBase.evaluatePlan(_roomPlacements);
    final score = audit['score'] as int;
    final ratingText = audit['ratingText'] as String;
    final ratingColor = audit['ratingColor'] as Color;
    final results = audit['results'] as List<Map<String, dynamic>>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Vastu Score Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF1E3A5F), const Color(0xFF2C5F8D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'House Vastu Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score / 100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ratingColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ratingColor, width: 1),
                        ),
                        child: Text(
                          ratingText,
                          style: TextStyle(
                            color: ratingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Circular Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 7,
                          backgroundColor: Colors.white12,
                          color: ratingColor,
                        ),
                      ),
                      Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              // Main Entrance Facing Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Plot / Main Entrance Facing:',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<VastuDirection>(
                    value: _houseFacing,
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F),
                    style: const TextStyle(
                      color: Color(0xFFFF8C00),
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: VastuDirection.east,
                        child: Text('East Facing'),
                      ),
                      DropdownMenuItem(
                        value: VastuDirection.north,
                        child: Text('North Facing'),
                      ),
                      DropdownMenuItem(
                        value: VastuDirection.west,
                        child: Text('West Facing'),
                      ),
                      DropdownMenuItem(
                        value: VastuDirection.south,
                        child: Text('South Facing'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _houseFacing = v);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section Title & Share Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Room-by-Room Audit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.share_rounded,
                  color: Color(0xFF25D366), size: 18),
              label: const Text(
                'Share Report',
                style: TextStyle(
                    color: Color(0xFF25D366), fontWeight: FontWeight.bold),
              ),
              onPressed: () => _shareAuditReport(audit),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Room Placement Cards
        ...results.map((res) {
          final RoomVastuRule rule = res['rule'];
          final VastuDirection currentDir = res['direction'];
          final VastuSuitability suit = res['suitability'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: suit.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(rule.icon, color: suit.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rule.roomName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Direction Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<VastuDirection>(
                        value: currentDir,
                        underline: const SizedBox(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: VastuDirection.northEast,
                            child: Text('North-East', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.east,
                            child: Text('East', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.southEast,
                            child: Text('South-East', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.south,
                            child: Text('South', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.southWest,
                            child: Text('South-West', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.west,
                            child: Text('West', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.northWest,
                            child: Text('North-West', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: VastuDirection.north,
                            child: Text('North', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        onChanged: (newDir) {
                          if (newDir != null) {
                            setState(() {
                              _roomPlacements[rule.roomKey] = newDir;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Suitability pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: suit.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            suit == VastuSuitability.defect
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            size: 14,
                            color: suit.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            suit.label,
                            style: TextStyle(
                              color: suit.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ideal: ${rule.bestDirection.shortName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Why / Scientific Note
                Text(
                  rule.why,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),

                // Remedy (if defect)
                if (suit == VastuSuitability.defect ||
                    suit == VastuSuitability.average) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_fix_high_rounded,
                            color: Color(0xFFFF8C00), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Quick Remedy: ${rule.remedy}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFC2410C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        const AppBannerAd(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: VASTU PRINCIPLES & REMEDIES GUIDE
  // ---------------------------------------------------------------------------
  Widget _buildGuideTab(bool isDark) {
    const principles = [
      {
        'title': '1. Pancha Bhuta (5 Elements) Harmony',
        'desc':
            'Water in North-East, Fire in South-East, Earth in South-West, Air in North-West, and Space in Center. Never place Fire (Kitchen) in the Water zone (North-East) or vice versa.',
        'icon': Icons.public_rounded,
      },
      {
        'title': '2. High & Heavy in South-West',
        'desc':
            'South-West must always be higher and heavier than North-East. Keep overhead water tanks, master bedrooms, and heavy storage in South-West to prevent financial and structural instability.',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': '3. Low & Light in North-East',
        'desc':
            'North-East (Ishanya) receives early morning ultraviolet rays that purify the home. Keep this quadrant uncluttered, light, and with maximum windows or underground water sumps.',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'title': '4. Brahmasthan (Cosmic Center)',
        'desc':
            'The central 1/9th part of any house is Brahmasthan (ruled by Lord Brahma). It must be kept free of heavy pillars, staircases, toilets, and walls for smooth positive energy flow.',
        'icon': Icons.crop_free_rounded,
      },
      {
        'title': '5. Proper Sleeping Alignment',
        'desc':
            'Never sleep with head towards North (Earth’s magnetic North repels the human body’s magnetic field, causing irregular blood pressure and insomnia). Sleep with head towards South or East.',
        'icon': Icons.hotel_rounded,
      },
      {
        'title': '6. Clockwise Staircases',
        'desc':
            'A staircase should always climb up in a clockwise direction (following the natural movement of the sun). Never build a puja room, toilet, or study beneath a staircase.',
        'icon': Icons.rotate_right_rounded,
      },
      {
        'title': '7. Non-Destructive Remedies',
        'desc':
            'You do NOT need to break walls to correct Vastu doshas. Use elemental color balancing, brass/copper metal strips, rock salt bowls, pyramids, and proper indoor plants.',
        'icon': Icons.spa_rounded,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: principles.length + 1,
      itemBuilder: (context, index) {
        if (index == principles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppBannerAd(),
          );
        }

        final p = principles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  p['icon'] as IconData,
                  color: const Color(0xFFFF8C00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['desc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

