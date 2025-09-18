/// Journey Library Screen for MindTrainer Pro
/// 
/// Displays available journey templates and user's custom journeys.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../domain/mindfulness_journey.dart';
import '../application/journey_service.dart';

class JourneyLibraryScreen extends StatefulWidget {
  final MindTrainerProGates proGates;
  final JourneyService journeyService;
  
  const JourneyLibraryScreen({
    super.key,
    required this.proGates,
    required this.journeyService,
  });
  
  @override
  State<JourneyLibraryScreen> createState() => _JourneyLibraryScreenState();
}

class _JourneyLibraryScreenState extends State<JourneyLibraryScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<MindfulnessJourney> _templates = [];
  List<MindfulnessJourney> _customJourneys = [];
  JourneyProgress? _activeProgress;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJourneys();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadJourneys() async {
    try {
      final templates = await widget.journeyService.getAvailableTemplates();
      final custom = await widget.journeyService.getCustomJourneys();
      final activeProgress = await widget.journeyService.getActiveJourneyProgress();
      
      if (mounted) {
        setState(() {
          _templates = templates;
          _customJourneys = custom;
          _activeProgress = activeProgress;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.library_books),
              text: 'Templates',
            ),
            Tab(
              icon: Icon(Icons.create),
              text: 'My Journeys',
            ),
          ],
        ),
        actions: [
          if (widget.proGates.isProActive)
            IconButton(
              onPressed: () => _showCreateJourneyDialog(),
              icon: const Icon(Icons.add),
              tooltip: 'Create Journey',
            ),
        ],
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Active journey banner
                if (_activeProgress != null)
                  _buildActiveJourneyBanner(),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTemplatesTab(),
                      _buildCustomJourneysTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildActiveJourneyBanner() {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.play_circle, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue Your Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${_activeProgress!.completionPercentage.toInt()}% complete • '
                  'Step ${_activeProgress!.currentStepIndex + 1} of ${_activeProgress!.stepProgress.length}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _continueActiveJourney(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return const Center(
        child: Text('No templates available'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final journey = _templates[index];
        return _buildJourneyCard(journey, isTemplate: true);
      },
    );
  }
  
  Widget _buildCustomJourneysTab() {
    return Column(
      children: [
        // Pro feature banner for free users
        if (!widget.proGates.isProActive)
          _buildProFeatureBanner(),
        
        // Custom journeys list
        Expanded(
          child: _customJourneys.isEmpty
              ? _buildEmptyCustomJourneys()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customJourneys.length,
                  itemBuilder: (context, index) {
                    final journey = _customJourneys[index];
                    return _buildJourneyCard(journey, isTemplate: false);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildProFeatureBanner() {
    return Container(
      color: Colors.amber[50],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Custom Journeys',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'Design your own mindfulness sequences tailored to your goals',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to Pro upgrade
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyCustomJourneys() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.create,
              size: 64,
              color: widget.proGates.isProActive ? Colors.grey : Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              widget.proGates.isProActive 
                  ? 'No Custom Journeys Yet'
                  : 'Custom Journeys (Pro)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.proGates.isProActive
                  ? 'Create your first personalized mindfulness journey'
                  : 'Upgrade to Pro to create unlimited custom journeys',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.proGates.isProActive 
                  ? () => _showCreateJourneyDialog()
                  : () {
                      // Navigate to Pro upgrade
                    },
              child: Text(
                widget.proGates.isProActive ? 'Create Journey' : 'Upgrade to Pro',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJourneyCard(MindfulnessJourney journey, {required bool isTemplate}) {
    final isProOnly = isTemplate && 
        JourneyTemplates.proTemplates.any((t) => t.id == journey.id) &&
        !widget.proGates.isProActive;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isProOnly ? _showProUpgradeDialog : () => _selectJourney(journey),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                journey.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isProOnly ? Colors.grey : null,
                                ),
                              ),
                            ),
                            if (isProOnly) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          journey.categoryDescription,
                          style: TextStyle(
                            color: _getCategoryColor(journey.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions menu for custom journeys
                  if (!isTemplate)
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleJourneyAction(action, journey),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                journey.description,
                style: TextStyle(
                  color: isProOnly ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Journey stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.schedule,
                    '${journey.estimatedDays} days',
                    isProOnly,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.list,
                    '${journey.steps.length} steps',
                    isProOnly,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.timer,
                    '${journey.totalEstimatedMinutes} min total',
                    isProOnly,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Difficulty and action button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(journey.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      journey.difficultyDescription,
                      style: TextStyle(
                        color: _getDifficultyColor(journey.difficulty),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isProOnly ? _showProUpgradeDialog : () => _selectJourney(journey),
                    child: Text(isProOnly ? 'Upgrade to Pro' : 'Start Journey'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatChip(IconData icon, String text, bool isDisabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDisabled ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDisabled ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(JourneyCategory category) {
    switch (category) {
      case JourneyCategory.stressRelief:
        return Colors.blue;
      case JourneyCategory.focusBuilding:
        return Colors.orange;
      case JourneyCategory.emotionalWellness:
        return Colors.green;
      case JourneyCategory.sleepPreparation:
        return Colors.purple;
      case JourneyCategory.energyBoost:
        return Colors.red;
      case JourneyCategory.habitBuilding:
        return Colors.teal;
      case JourneyCategory.custom:
        return Colors.grey;
    }
  }
  
  Color _getDifficultyColor(JourneyDifficulty difficulty) {
    switch (difficulty) {
      case JourneyDifficulty.beginner:
        return Colors.green;
      case JourneyDifficulty.intermediate:
        return Colors.orange;
      case JourneyDifficulty.advanced:
        return Colors.red;
    }
  }
  
  void _selectJourney(MindfulnessJourney journey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(journey.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(journey.description),
            const SizedBox(height: 16),
            Text(
              'This journey has ${journey.steps.length} steps and is estimated to take ${journey.estimatedDays} days to complete.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startJourney(journey);
            },
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startJourney(MindfulnessJourney journey) async {
    final progress = await widget.journeyService.startJourney(journey.id);
    if (progress != null) {
      await _loadJourneys(); // Refresh to show active journey
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started "${journey.title}" journey!'),
            action: SnackBarAction(
              label: 'Continue',
              onPressed: _continueActiveJourney,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start journey. Please try again.'),
          ),
        );
      }
    }
  }
  
  void _continueActiveJourney() {
    // Navigate to active journey screen
    Navigator.pushNamed(context, '/journey/active');
  }
  
  void _showCreateJourneyDialog() {
    // Navigate to journey builder screen
    Navigator.pushNamed(context, '/journey/create');
  }
  
  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro Feature'),
        content: const Text('This journey requires a Pro subscription to access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to Pro upgrade
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }
  
  void _handleJourneyAction(String action, MindfulnessJourney journey) {
    switch (action) {
      case 'edit':
        // Navigate to edit journey screen
        Navigator.pushNamed(context, '/journey/edit', arguments: journey);
        break;
      case 'duplicate':
        _duplicateJourney(journey);
        break;
      case 'delete':
        _confirmDeleteJourney(journey);
        break;
    }
  }
  
  Future<void> _duplicateJourney(MindfulnessJourney journey) async {
    final duplicated = await widget.journeyService.createCustomJourney(
      title: '${journey.title} (Copy)',
      description: journey.description,
      category: journey.category,
      difficulty: journey.difficulty,
      steps: journey.steps,
      tags: journey.tags,
    );
    
    if (duplicated != null) {
      await _loadJourneys();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey duplicated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to duplicate journey')),
        );
      }
    }
  }
  
  void _confirmDeleteJourney(MindfulnessJourney journey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journey'),
        content: Text('Are you sure you want to delete "${journey.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteJourney(journey);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteJourney(MindfulnessJourney journey) async {
    final success = await widget.journeyService.deleteCustomJourney(journey.id);
    if (success) {
      await _loadJourneys();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey deleted successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete journey')),
        );
      }
    }
  }
}