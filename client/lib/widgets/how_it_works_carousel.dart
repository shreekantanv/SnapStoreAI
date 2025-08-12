import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:client/models/how_it_works_step.dart';

class HowItWorksCarousel extends StatelessWidget {
  final List<HowItWorksStep> steps;

  const HowItWorksCarousel({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it works', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        CarouselSlider.builder(
          itemCount: steps.length,
          options: CarouselOptions(
            // remove fixed height; let slides size themselves
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.82,
          ),
          itemBuilder: (context, index, realIdx) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: AspectRatio(
                aspectRatio: 16 / 9, // keeps a stable height across devices
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image gets the available top space
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              step.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title stays on one or two lines max
                        Text(
                          step.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description flexes last; ellipsizes if tight
                        Flexible(
                          child: Text(
                            step.description,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
}
