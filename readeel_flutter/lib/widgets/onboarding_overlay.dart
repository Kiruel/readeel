import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const OnboardingOverlay({super.key, required this.onDismiss});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        settingsController.markOnboardingAsSeen();
        widget.onDismiss();
      },
      onHorizontalDragEnd: (details) {
        settingsController.markOnboardingAsSeen();
        widget.onDismiss();
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.swipe_left,
                size: 100,
                color: Colors.white,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveX(begin: 50, end: -50, duration: 1.seconds, curve: Curves.easeInOut)
                  .fade(begin: 0, end: 1, duration: 300.ms)
                  .then(delay: 500.ms)
                  .fade(begin: 1, end: 0, duration: 200.ms),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.swipeLeftToNext,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
