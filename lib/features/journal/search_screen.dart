import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Journal search and filter screen
class JournalSearchScreen extends StatefulWidget {
  const JournalSearchScreen({super.key});

  @override
  State<JournalSearchScreen> createState() => _JournalSearchScreenState();
}

class _JournalSearchScreenState extends State<JournalSearchScreen> {
  final _searchController = TextEditingController();
  List<String> _allEntries = [];
  List<String> _filteredEntries = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final sp = await SharedPreferences.getInstance();
    final entries = sp.getStringList('journal_entries') ?? [];
    
    setState(() {
      _allEntries = entries.reversed.toList(); // Most recent first
      _filteredEntries = _allEntries;
      _isLoading = false;
    });
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        final parts = entry.split('|');
        if (parts.length < 3) return false;
        
        final type = parts[1];
        final content = parts[2].toLowerCase();
        
        // Filter by type
        if (_selectedFilter != 'all' && type != _selectedFilter) {
          return false;
        }
        
        // Filter by search query
        if (query.isNotEmpty && !content.contains(query)) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  String _formatEntry(String entry) {
    final parts = entry.split('|');
    if (parts.length < 3) return entry;
    
    final timestamp = DateTime.tryParse(parts[0]);
    final type = parts[1];
    final content = parts[2];
    
    final dateStr = timestamp != null 
        ? '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
        : 'Unknown date';
    
    final typeIcon = switch (type) {
      'text' => '📝',
      'voice' => '🎤',
      'photo' => '📷',
      _ => '📄',
    };
    
    return '$typeIcon $dateStr\n${content.length > 100 ? '${content.substring(0, 100)}...' : content}';
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Search Journal',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2436),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterEntries(),
                    style: TextStyle(
                      color: const Color(0xFFF2F5F7),
                      fontSize: (16 * textScaler).toDouble(),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search your entries...',
                      hintStyle: TextStyle(color: Color(0xFFC7D1DD)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFC7D1DD)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter chips
                Row(
                  children: [
                    Text(
                      'Filter:',
                      style: TextStyle(
                        color: const Color(0xFFF2F5F7),
                        fontSize: (14 * textScaler).toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('All', 'all'),
                          _buildFilterChip('Text', 'text'),
                          _buildFilterChip('Voice', 'voice'),
                          _buildFilterChip('Photo', 'photo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Color(0xFFC7D1DD),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allEntries.isEmpty
                                  ? 'No journal entries yet'
                                  : 'No entries match your search',
                              style: TextStyle(
                                color: const Color(0xFFC7D1DD),
                                fontSize: (16 * textScaler).toDouble(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2436),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(width: 1.2, color: const Color(0xA3274862)),
                            ),
                            child: ListTile(
                              title: Text(
                                _formatEntry(entry),
                                style: TextStyle(
                                  color: const Color(0xFFF2F5F7),
                                  fontSize: (14 * textScaler).toDouble(),
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _filterEntries();
      },
      backgroundColor: const Color(0xFF0F2436),
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFFC7D1DD),
      ),
      side: const BorderSide(color: Color(0xA3274862)),
    );
  }
}