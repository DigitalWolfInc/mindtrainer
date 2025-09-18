import 'package:flutter/material.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../achievements/achievements_store.dart';
import '../../achievements/badge.dart' as ach;
import '../../a11y/a11y.dart';

/// Animal badges screen showing progress from check-ins
class AnimalBadgesScreen extends StatefulWidget {
  const AnimalBadgesScreen({super.key});

  @override
  State<AnimalBadgesScreen> createState() => _AnimalBadgesScreenState();
}

class _AnimalBadgesScreenState extends State<AnimalBadgesScreen> {
  late Future<List<ach.Badge>> _animalBadges;
  late Future<Map<String, int>> _animalCounts;

  @override
  void initState() {
    super.initState();
    _animalBadges = AchievementsStore.instance.fetchByCategory('animal');
    _animalCounts = AchievementsStore.instance.getAnimalCounts();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Animal Badges',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([_animalBadges, _animalCounts]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final badges = snapshot.data![0] as List<ach.Badge>;
          final counts = snapshot.data![1] as Map<String, int>;

          if (badges.isEmpty && counts.isEmpty) {
            return _buildEmptyState(textScaler);
          }

          // Group badges by species
          final badgesBySpecies = <String, List<ach.Badge>>{};
          for (final badge in badges) {
            final species = badge.meta?['species'] as String? ?? 'unknown';
            badgesBySpecies.putIfAbsent(species, () => []).add(badge);
          }

          // Include species with counts but no badges yet
          for (final species in counts.keys) {
            badgesBySpecies.putIfAbsent(species, () => []);
          }

          final species = badgesBySpecies.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: species.length,
            itemBuilder: (context, index) {
              final speciesName = species[index];
              final speciesBadges = badgesBySpecies[speciesName] ?? [];
              final speciesCount = counts[speciesName] ?? 0;
              
              return _buildSpeciesSection(
                speciesName, 
                speciesBadges, 
                speciesCount, 
                textScaler,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(double textScaler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets_outlined,
              size: 64,
              color: Color(0xFFC7D1DD),
            ),
            const SizedBox(height: 24),
            Text(
              'No Animal Badges Yet',
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (20 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Check in with how you\'re feeling to start earning animal badges!',
              style: TextStyle(
                color: const Color(0xFFC7D1DD),
                fontSize: (16 * textScaler).toDouble(),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesSection(
    String species, 
    List<ach.Badge> badges, 
    int count, 
    double textScaler,
  ) {
    final speciesEmoji = {
      'rabbit': '🐰',
      'turtle': '🐢', 
      'cat': '🐱',
      'owl': '🦉',
      'dolphin': '🐬',
      'deer': '🦌',
    };

    final emoji = speciesEmoji[species] ?? '🐾';
    final displayName = species[0].toUpperCase() + species.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2436),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1.2, color: const Color(0xA3274862)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: (32 * textScaler).toDouble()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: const Color(0xFFF2F5F7),
                          fontSize: (18 * textScaler).toDouble(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$count check-ins',
                        style: TextStyle(
                          color: const Color(0xFFC7D1DD),
                          fontSize: (14 * textScaler).toDouble(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: 4, // Always show 4 milestones: 1, 7, 30, 100
              itemBuilder: (context, index) {
                final thresholds = [1, 7, 30, 100];
                final threshold = thresholds[index];
                final badge = badges.cast<ach.Badge>().firstWhere(
                  (b) => b.meta?['threshold'] == threshold,
                  orElse: () => ach.Badge.create(
                    id: 'locked_$species$threshold',
                    title: _getTitleForThreshold(threshold, emoji),
                    description: 'Check in $threshold times to unlock',
                    unlockedAt: DateTime.now(),
                  ),
                );

                final isUnlocked = count >= threshold;
                final progress = count / threshold;

                return _buildBadgeCard(badge, isUnlocked, progress, textScaler);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(ach.Badge badge, bool isUnlocked, double progress, double textScaler) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.2, 
          color: isUnlocked 
              ? const Color(0xFF6366F1) 
              : const Color(0xA3274862),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            badge.title,
            style: TextStyle(
              color: isUnlocked 
                  ? const Color(0xFFF2F5F7) 
                  : const Color(0xFFC7D1DD).withOpacity(0.6),
              fontSize: (12 * textScaler).toDouble(),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (isUnlocked) ...[
            const Icon(
              Icons.check_circle,
              color: Color(0xFF6366F1),
              size: 16,
            ),
          ] else ...[
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xA3274862),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTitleForThreshold(int threshold, String emoji) {
    final titles = {
      1: "First Paws",
      7: "Weekly Pal", 
      30: "Loyal Companion",
      100: "Pack Leader",
    };
    return '${titles[threshold] ?? 'Animal Friend'} $emoji';
  }
}