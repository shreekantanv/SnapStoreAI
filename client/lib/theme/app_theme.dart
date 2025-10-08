import 'package:flutter/material.dart';

class PremiumGradients extends ThemeExtension<PremiumGradients> {
  const PremiumGradients({
    required this.scaffoldGradient,
    required this.cardGradient,
    required this.heroGlow,
  });

  final LinearGradient scaffoldGradient;
  final LinearGradient cardGradient;
  final LinearGradient heroGlow;

  @override
  PremiumGradients copyWith({
    LinearGradient? scaffoldGradient,
    LinearGradient? cardGradient,
    LinearGradient? heroGlow,
  }) {
    return PremiumGradients(
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      heroGlow: heroGlow ?? this.heroGlow,
    );
  }

  @override
  ThemeExtension<PremiumGradients> lerp(
    covariant ThemeExtension<PremiumGradients>? other,
    double t,
  ) {
    if (other is! PremiumGradients) {
      return this;
    }

    return PremiumGradients(
      scaffoldGradient: LinearGradient.lerp(
            scaffoldGradient,
            other.scaffoldGradient,
            t,
          ) ??
          scaffoldGradient,
      cardGradient: LinearGradient.lerp(
            cardGradient,
            other.cardGradient,
            t,
          ) ??
          cardGradient,
      heroGlow: LinearGradient.lerp(heroGlow, other.heroGlow, t) ?? heroGlow,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF5B3CC4),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8DEFF),
      onPrimaryContainer: Color(0xFF220063),
      secondary: Color(0xFF4F77FF),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCE4FF),
      onSecondaryContainer: Color(0xFF001946),
      tertiary: Color(0xFFFFB74D),
      onTertiary: Color(0xFF382100),
      tertiaryContainer: Color(0xFFFFE2B3),
      onTertiaryContainer: Color(0xFF2A1700),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFDF8FF),
      onSurface: Color(0xFF201A2A),
      surfaceTint: Color(0xFF5B3CC4),
      surfaceVariant: Color(0xFFE8E0F0),
      onSurfaceVariant: Color(0xFF4A4256),
      outline: Color(0xFF7A7285),
      outlineVariant: Color(0xFFCFC6D9),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF352F3E),
      inverseOnSurface: Color(0xFFF1EAF9),
      background: Color(0xFFF8F5FF),
      onBackground: Color(0xFF1B1724),
    );

    return _baseTheme(colorScheme).copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        PremiumGradients(
          scaffoldGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF6FF),
              Color(0xFFF6F7FF),
              Color(0xFFFDFBFF),
            ],
          ),
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF4F1FF),
            ],
          ),
          heroGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7055FF),
              Color(0xFF6EC3FF),
            ],
          ),
        ),
      ],
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFD0BCFF),
      onPrimary: Color(0xFF381E72),
      primaryContainer: Color(0xFF4F378B),
      onPrimaryContainer: Color(0xFFEADDFF),
      secondary: Color(0xFFACC7FF),
      onSecondary: Color(0xFF002F67),
      secondaryContainer: Color(0xFF214780),
      onSecondaryContainer: Color(0xFFD6E3FF),
      tertiary: Color(0xFFFFD18F),
      onTertiary: Color(0xFF432C00),
      tertiaryContainer: Color(0xFF5E4100),
      onTertiaryContainer: Color(0xFFFFE0B8),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF12101B),
      onSurface: Color(0xFFE7DEF1),
      surfaceTint: Color(0xFFD0BCFF),
      surfaceVariant: Color(0xFF4A4256),
      onSurfaceVariant: Color(0xFFCCC2DC),
      outline: Color(0xFF958CA8),
      outlineVariant: Color(0xFF4A4256),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE7DEF1),
      inverseOnSurface: Color(0xFF1A1524),
      background: Color(0xFF0E0D14),
      onBackground: Color(0xFFE7DEF1),
    );

    return _baseTheme(colorScheme).copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        PremiumGradients(
          scaffoldGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E0D18),
              Color(0xFF151326),
            ],
          ),
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1A2C),
              Color(0xFF1A2535),
            ],
          ),
          heroGlow: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7762F6),
              Color(0xFF4AB3FF),
            ],
          ),
        ),
      ],
    );
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = baseTextTheme.merge(const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onBackground,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surface.withOpacity(
          colorScheme.brightness == Brightness.dark ? 0.8 : 0.95,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.95),
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.95),
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        elevation: 0,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium;
          if (states.contains(MaterialState.selected)) {
            return base?.copyWith(color: colorScheme.primary);
          }
          return base?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        side: BorderSide(color: colorScheme.outlineVariant),
        backgroundColor: colorScheme.surface.withOpacity(
          colorScheme.brightness == Brightness.dark ? 0.6 : 0.9,
        ),
        selectedColor: colorScheme.primary.withOpacity(0.18),
        labelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.inverseOnSurface,
        ),
        actionTextColor: colorScheme.tertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(
          colorScheme.brightness == Brightness.dark ? 0.35 : 0.9,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.7),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 24,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        iconColor: colorScheme.primary,
        tileColor: colorScheme.surface.withOpacity(
          colorScheme.brightness == Brightness.dark ? 0.4 : 0.9,
        ),
      ),
    );
  }
}
