import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'relay_icons.dart';

class SystemScreen extends StatefulWidget {
  final Map<dynamic, dynamic> liveData;
  final bool isConnected;
  final Map<String, String> relayNames;
  final Map<String, String> relayIcons;
  final VoidCallback onSettingsChanged;

  const SystemScreen({
    super.key,
    required this.liveData,
    required this.isConnected,
    required this.relayNames,
    required this.relayIcons,
    required this.onSettingsChanged,
  });

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  final TextEditingController _userNameController = TextEditingController(text: 'Admin');
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selectedIcons = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    for (int i = 1; i <= 4; i++) {
      _controllers[i.toString()] = TextEditingController(text: widget.relayNames[i.toString()]);
      _selectedIcons[i.toString()] = widget.relayIcons[i.toString()] ?? 'power';
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Admin';
    if (mounted) {
      setState(() {
        _userNameController.text = name;
      });
    }
  }

  Future<void> _saveUserName() async {
    final name = _userNameController.text.trim();
    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    widget.onSettingsChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin Name updated!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _saveRelaySettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    
    for (int i = 1; i <= 4; i++) {
      await prefs.setString('relay_name_$i', _controllers[i.toString()]!.text.trim());
      await prefs.setString('relay_icon_$i', _selectedIcons[i.toString()]!);
    }
    
    widget.onSettingsChanged();
    setState(() => _isSaving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relay UI settings saved!')));
  }

  void _showRelayIconPicker(int relayNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RelayIconPickerSheet(
          relayNumber: relayNumber,
          relayName: _controllers[relayNumber.toString()]?.text.trim().isNotEmpty == true
              ? _controllers[relayNumber.toString()]!.text.trim()
              : 'Relay $relayNumber',
          currentIconKey: _selectedIcons[relayNumber.toString()] ?? 'power',
          onIconSelected: (key) {
            setState(() {
              _selectedIcons[relayNumber.toString()] = key;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esp32Online = widget.liveData['online'] == true && widget.isConnected;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('SETTINGS', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text('Personalization', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),

        // Administrator Profile Section (Replaces Brand Logo)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Administrator Profile', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('This display name appears in the Overview dashboard header.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Admin Name',
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2DD4BF), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF020617),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: const Color(0xFF042F2E),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveUserName,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Relay Configuration (Name AND Icon)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Relay Interface', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${kRelayIcons.length}+ Logos',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize relay labels and tap the icon button to choose from 77+ specialized logos.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) {
                int r = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Tap to change logo (Current: ${getRelayIconLabel(_selectedIcons[r.toString()])})',
                        child: InkWell(
                          onTap: () => _showRelayIconPicker(r),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF020617),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  getRelayIcon(_selectedIcons[r.toString()]),
                                  color: const Color(0xFF2DD4BF),
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllers[r.toString()],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Relay $r Name',
                            helperText: 'Logo: ${getRelayIconLabel(_selectedIcons[r.toString()])}',
                            helperStyle: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11),
                            labelStyle: const TextStyle(color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFF020617),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: const Color(0xFF042F2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveRelaySettings,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF042F2E)))
                      : const Text('SAVE UI LAYOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Status Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.13))),
          child: Column(
            children: [
              _buildSystemRow('Firebase DB', widget.isConnected ? 'CONNECTED' : 'WAITING', widget.isConnected ? const Color(0xFF34D399) : const Color(0xFFFBBF24)),
              const Divider(color: Color(0xFF1E293B), height: 32),
              _buildSystemRow('ESP32 Hardware', esp32Online ? 'ONLINE' : 'OFFLINE', esp32Online ? const Color(0xFF34D399) : const Color(0xFFFB7185)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sign Out Section
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFB7185),
              side: BorderSide(color: const Color(0xFFFB7185).withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'SIGN OUT',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSystemRow(String label, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _RelayIconPickerSheet extends StatefulWidget {
  final int relayNumber;
  final String relayName;
  final String currentIconKey;
  final ValueChanged<String> onIconSelected;

  const _RelayIconPickerSheet({
    required this.relayNumber,
    required this.relayName,
    required this.currentIconKey,
    required this.onIconSelected,
  });

  @override
  State<_RelayIconPickerSheet> createState() => _RelayIconPickerSheetState();
}

class _RelayIconPickerSheetState extends State<_RelayIconPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RelayIconItem> get _filteredIcons {
    return kRelayIcons.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.label.toLowerCase().contains(q) ||
          item.key.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIcons;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Relay Logo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Relay ${widget.relayNumber} • ${widget.relayName}',
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search logos (e.g. pump, fan, heater, light, feeder)...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2DD4BF), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF020617),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: const Color(0xFF1E293B).withValues(alpha: 0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: const Color(0xFF1E293B).withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                ),
              ),
            ),
          ),

          // Category filter pills
          Container(
            height: 38,
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: kRelayCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final category = kRelayCategories[idx];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF042F2E) : const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  backgroundColor: const Color(0xFF020617),
                  selectedColor: const Color(0xFF2DD4BF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1E293B),
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Grid of logos
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Color(0xFF64748B), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No logos found for "$_searchQuery"',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text('Reset Search', style: TextStyle(color: Color(0xFF2DD4BF))),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 85,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final isSelected = widget.currentIconKey == item.key;
                      return InkWell(
                        onTap: () {
                          widget.onIconSelected(item.key);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2DD4BF).withValues(alpha: 0.16)
                                : const Color(0xFF020617),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFF1E293B),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? const Color(0xFF2DD4BF)
                                    : Colors.white70,
                                size: 26,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}