import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/mtds/mtds.dart';

void main() {
  group('MTDS Components Golden Tests', () {
    testWidgets('MtdsStackCard golden test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MtdsTheme.midnightCalm(),
          home: MtdsScaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MtdsStackCard(
                    title: 'Sample Card',
                    subtitle: 'This is a subtitle',
                    leadingIcon: Icons.star,
                    onTap: () {},
                    trailing: const MtdsTimeBadge(minutes: 5),
                  ),
                  const SizedBox(height: 16),
                  MtdsStackCard(
                    title: 'Disabled Card',
                    subtitle: 'This card is disabled',
                    leadingIcon: Icons.block,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mtds_stack_card.png'),
      );
    });

    testWidgets('MtdsPrimaryPillButton golden test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MtdsTheme.midnightCalm(),
          home: MtdsScaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MtdsPrimaryPillButton(
                    text: 'Primary Button',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  MtdsPrimaryPillButton(
                    text: 'With Icon',
                    icon: Icons.star,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  MtdsPrimaryPillButton(
                    text: 'Disabled Button',
                    state: MtdsButtonState.disabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mtds_primary_pill_button.png'),
      );
    });

    testWidgets('MtdsChip golden test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MtdsTheme.midnightCalm(),
          home: MtdsScaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MtdsChip.selectable(
                    text: 'Selected',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  MtdsChip.selectable(
                    text: 'Unselected',
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  MtdsChip.enabled(
                    text: 'Disabled',
                    selected: false,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mtds_chip.png'),
      );
    });
  });
}