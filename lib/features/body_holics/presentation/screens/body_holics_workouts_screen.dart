import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/providers/subscription_provider.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';
import 'package:the_holics/shared/widgets/exercise/exercise_player.dart';

class BodyHolicsWorkoutsScreen extends ConsumerWidget {
  const BodyHolicsWorkoutsScreen({super.key});

  static const Set<String> _hiddenAnimations = {
    'squat',
    'plank',
    'mountain_climber',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final firestore = ref.watch(firestoreServiceProvider);
    final hasActiveSubscriptionAsync =
        ref.watch(currentUserHasActiveSubscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Body Holics Workouts'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bodyHolicsOrange.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.06),
              ),
            ),
          ),
          uid == null
          ? const Center(
              child: Text(
                'Please sign in first.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : StreamBuilder<Map<String, dynamic>?>(
              stream: firestore.userSubscriptionRequestStream(uid),
              builder: (context, subSnap) {
                final requestStatus =
                    (subSnap.data?['status']?.toString().toLowerCase() ?? 'inactive');
                final isActive = hasActiveSubscriptionAsync.maybeWhen(
                  data: (isActive) => isActive,
                  orElse: () => false,
                );

                if (!isActive) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _StaggerReveal(
                        delayFactor: 0.10,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                color: AppTheme.textSecondary,
                                size: 40,
                              ),
                              const Gap(12),
                              Text(
                                requestStatus == 'pending'
                                    ? 'Your subscription is pending admin approval.'
                                    : 'You need an active subscription to access workouts.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                              const Gap(16),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                child: const Text('Back to Body Holics'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final workoutsAsync = ref.watch(workoutsProvider);
                return workoutsAsync.when(
                  data: (items) {
                    final cloudItems = items
                        .map(
                          (w) => _DisplayExercise(
                            id: w.id,
                            title: w.title,
                            durationMin: w.durationMin,
                            difficulty: w.difficulty,
                            animationName: _toAnimationName(w.title),
                          ),
                        )
                        .toList();

                    return FutureBuilder<List<_DisplayExercise>>(
                      future: _resolveDisplayExercises(cloudItems),
                      builder: (context, assetSnap) {
                        if (assetSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final displayItems =
                            (assetSnap.data == null || assetSnap.data!.isEmpty)
                                ? _defaultExercises()
                                : assetSnap.data!;
                        final isNarrowPhone =
                          MediaQuery.of(context).size.width < 390;
                        final cardAspectRatio = isNarrowPhone ? 0.72 : 0.80;

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                                child: _StaggerReveal(
                                  delayFactor: 0.06,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF2A190D), Color(0xFF171717)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.bodyHolicsOrange.withOpacity(0.24),
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Workout Library',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Gap(4),
                                        Text(
                                          'Build consistency with guided exercise animations.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final w = displayItems[index];
                                    return _StaggerReveal(
                                      delayFactor: (0.10 + (index * 0.04)).clamp(0.10, 0.75),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [AppTheme.surfaceCard, Color(0xFF1A1A1A)],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppTheme.borderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ExercisePlayer(
                                                  key: ValueKey('workout_anim_${w.id}'),
                                                  animationName: w.animationName,
                                                  aspectRatio: 4 / 3,
                                                ),
                                              ),
                                            ),
                                            const Gap(8),
                                            Text(
                                              w.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Gap(2),
                                            Text(
                                              '${w.durationMin} min • ${w.difficulty}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: displayItems.length,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: cardAspectRatio,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _toAnimationName(String title) {
    final normalized = title.trim().toLowerCase();

    if (normalized.contains('push')) return 'pushup';
    if (normalized.contains('squat')) return 'squat';
    if (normalized.contains('plank')) return 'plank';
    if (normalized.contains('burpee')) return 'burpee';
    if (normalized.contains('mountain')) return 'mountain_climber';

    final slug = normalized.replaceAll(RegExp(r'\s+'), '_');
    return slug.isEmpty ? 'pushup' : slug;
  }

  Future<List<_DisplayExercise>> _resolveDisplayExercises(
      List<_DisplayExercise> cloudItems) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/animations/') && path.endsWith('.json'),
        )
        .toSet()
        .toList()
      ..sort();

    final fromAssets = keys.map((path) {
      final fileName = path.split('/').last.replaceAll('.json', '');
      return _DisplayExercise(
        id: 'asset_$fileName',
        title: _titleFromSlug(fileName),
        durationMin: 12,
        difficulty: 'Beginner',
        animationName: fileName,
      );
    }).toList();

    final mergedByAnimation = <String, _DisplayExercise>{};

    // Always include defaults so all core exercises are visible.
    for (final ex in _defaultExercises()) {
      mergedByAnimation[ex.animationName] = ex;
    }

    // Add any uploaded local animations.
    for (final ex in fromAssets) {
      mergedByAnimation.putIfAbsent(ex.animationName, () => ex);
    }

    // Cloud workouts override metadata for matching animations.
    for (final ex in cloudItems) {
      mergedByAnimation[ex.animationName] = ex;
    }

    return mergedByAnimation.values
        .where((ex) => !_hiddenAnimations.contains(ex.animationName))
        .toList();
  }

  String _titleFromSlug(String slug) {
    return slug
        .split('_')
        .where((s) => s.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  List<_DisplayExercise> _defaultExercises() {
    return [
      _DisplayExercise(
        id: 'default_pushups',
        title: 'Push Up',
        durationMin: 12,
        difficulty: 'Beginner',
        animationName: 'pushup',
      ),
      _DisplayExercise(
        id: 'default_burpees',
        title: 'Burpee',
        durationMin: 14,
        difficulty: 'Intermediate',
        animationName: 'burpee',
      ),
    ];
  }
}

class _StaggerReveal extends StatelessWidget {
  final Widget child;
  final double delayFactor;

  const _StaggerReveal({
    required this.child,
    required this.delayFactor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, widgetChild) {
        final progress = Interval(delayFactor, 1.0, curve: Curves.easeOutCubic)
            .transform(value.clamp(0.0, 1.0));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _DisplayExercise {
  final String id;
  final String title;
  final int durationMin;
  final String difficulty;
  final String animationName;

  const _DisplayExercise({
    required this.id,
    required this.title,
    required this.durationMin,
    required this.difficulty,
    required this.animationName,
  });
}
