import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';

class SkinHolicsGalleryScreen extends StatelessWidget {
  const SkinHolicsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = <_ResultItem>[
      const _ResultItem(
        title: 'Acne Recovery',
        duration: '6 weeks program',
        accent: Color(0xFFE91E8C),
        assetPath: 'assets/images/skin_holics/gallery/acne_recovery.jpeg',
        details:
            'A targeted skin-clearing procedure designed to reduce active breakouts, calm inflammation, and support smoother texture.',
      ),
      const _ResultItem(
        title: 'Tag Removal',
        duration: '8 weeks program',
        accent: Color(0xFFFF6FB6),
        assetPath: 'assets/images/skin_holics/gallery/Tag Removal.jpeg',
        details:
            'A focused removal treatment for skin tags and minor surface irregularities, with post-care guidance for a clean recovery.',
      ),
      const _ResultItem(
        title: 'Laser Hair Removal',
        duration: '4 weeks program',
        accent: Color(0xFFFF8AC5),
        assetPath: 'assets/images/skin_holics/gallery/laser.jpeg',
        details:
            'Laser sessions aimed at reducing unwanted hair growth with progressive thinning, smoother skin, and long-term maintenance benefits.',
      ),
      const _ResultItem(
        title: 'Hair Treatment',
        duration: '10 weeks program',
        accent: Color(0xFFFF4FA7),
        assetPath: 'assets/images/skin_holics/gallery/hair_treatment.jpeg',
        details:
            'A restorative treatment plan focused on scalp health, hair strength, and visible improvement in density and texture.',
      ),
      const _ResultItem(
        title: 'Skin Transformation',
        duration: '12 weeks program',
        accent: Color(0xFFE85DA7),
        assetPath: 'assets/images/skin_holics/gallery/Skin_transformation.jpeg',
        details:
            'A full-scope skin improvement program focused on tone correction, texture smoothing, and overall complexion balance.',
      ),
      const _ResultItem(
        title: 'Skin Filler',
        duration: '6 weeks program',
        accent: Color(0xFFFF8CCF),
        assetPath: 'assets/images/skin_holics/gallery/Skin_filler.jpeg',
        details:
            'A specialized filler-based cosmetic treatment designed to refine contour balance and restore a more even appearance.',
      ),
      const _ResultItem(
        title: 'Microneedling',
        duration: '5 weeks program',
        accent: Color(0xFFFF5C9F),
        assetPath: 'assets/images/skin_holics/gallery/microneddleing.jpeg',
        details:
            'A skin-rejuvenation procedure that stimulates renewal, helps reduce visible marks, and supports smoother texture over time.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.skinHolics);
            }
          },
        ),
        title: const Text('Our Results Gallery'),
      ),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 2),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bodyHolicsOrange.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggerReveal(
                  delayFactor: 0.04,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF321523), Color(0xFF161616)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.skinHolichPink.withOpacity(0.25),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real client transformations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Gap(6),
                        Text(
                          'Before and after highlights from Skin Holics treatments.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _StaggerReveal(
                        delayFactor: (0.12 + (index * 0.08)).clamp(0.12, 0.70),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showResultDetails(context, item),
                            child: HolicsCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            item.assetPath,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.18),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.30),
                                                borderRadius: BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.16),
                                                ),
                                              ),
                                              child: const Text(
                                                'Tap to open',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    item.duration,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDetails(BuildContext context, _ResultItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: item.accent.withOpacity(0.20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 12),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.12,
                        child: Image.asset(
                          item.assetPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            item.duration,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Gap(14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Text(
                              item.details,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const Gap(14),
                          Row(
                            children: [
                              _DetailChip(label: 'Procedure', value: item.title),
                              const Gap(10),
                              _DetailChip(label: 'Duration', value: item.duration),
                            ],
                          ),
                          const Gap(16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go(AppRoutes.skinHolics);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: item.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Book this treatment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

class _ResultItem {
  final String title;
  final String duration;
  final Color accent;
  final String assetPath;
  final String details;

  const _ResultItem({
    required this.title,
    required this.duration,
    required this.accent,
    required this.assetPath,
    required this.details,
  });
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const Gap(4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
