import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../main.dart'; // To access settingsController

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                AppLocalizations.of(context)!.appearance,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _AdaptivePicker<ThemeMode>(
                value: settingsController.themeMode,
                items: const [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ],
                labelBuilder: (ThemeMode mode) {
                  switch (mode) {
                    case ThemeMode.system:
                      return AppLocalizations.of(context)!.systemDefault;
                    case ThemeMode.light:
                      return AppLocalizations.of(context)!.lightMode;
                    case ThemeMode.dark:
                      return AppLocalizations.of(context)!.darkMode;
                  }
                },
                onChanged: (ThemeMode? newValue) {
                  settingsController.updateThemeMode(newValue);
                },
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.content,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _AdaptivePicker<String?>(
                value: settingsController.languageCode,
                items: const [null, 'en', 'fr', 'it', 'de', 'es'],
                labelBuilder: (String? code) {
                  switch (code) {
                    case 'en':
                      return AppLocalizations.of(context)!.english;
                    case 'fr':
                      return AppLocalizations.of(context)!.french;
                    case 'it':
                      return AppLocalizations.of(context)!.italian;
                    case 'de':
                      return AppLocalizations.of(context)!.german;
                    case 'es':
                      return AppLocalizations.of(context)!.spanish;
                    default:
                      return AppLocalizations.of(context)!.systemDefault;
                  }
                },
                onChanged: (String? newValue) {
                  settingsController.updateLanguageCode(newValue);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdaptivePicker<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _AdaptivePicker({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelBuilder(value),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ],
          ),
          onPressed: () {
            showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 250,
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    top: false,
                    child: CupertinoPicker(
                      itemExtent: 32.0,
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            items.contains(value) ? items.indexOf(value) : 0,
                      ),
                      onSelectedItemChanged: (int index) {
                        onChanged(items[index]);
                      },
                      children: items.map((T item) {
                        return Center(
                          child: Text(
                            labelBuilder(item),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return DropdownButton<T>(
      value: value,
      isExpanded: true,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
