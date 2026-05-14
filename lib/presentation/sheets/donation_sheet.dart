import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/donation_provider.dart';
import '../theme/app_theme.dart';
import '../../domain/models/donation_product.dart';

class DonationSheet extends StatelessWidget {
  const DonationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DonationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: AppTheme.glassDecoration(
              isDark: isDark,
              borderRadius: 32,
              borderColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DragHandle(),
                SizedBox(height: 24),
                _Header(),
                SizedBox(height: 32),
                _ProductList(),
                SizedBox(height: 32),
                _RestoreButton(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.favorite_rounded, size: 40, color: primary),
        ),
        const SizedBox(height: 20),
        Text(
          "Support Privacy Tracker",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: AppTheme.fontFamily,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "This app is ad-free and privacy-first. Your support helps keep it that way.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final product in provider.products)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _ProductCard(
                      product: product,
                      onTap: () => provider.purchase(product),
                    ),
                  ),
                ),
              if (provider.products.isEmpty && !provider.isLoading)
                const Expanded(
                  child: Center(
                    child: Text("No products available at the moment."),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final DonationProduct product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: product.isSubscription
                ? PremiumGradients.accentGradient
                : [
                    primary.withValues(alpha: 0.1),
                    primary.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: product.isSubscription
                ? Colors.transparent
                : primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              product.isSubscription ? Icons.stars_rounded : Icons.coffee_rounded,
              size: 32,
              color: product.isSubscription ? Colors.white : primary,
            ),
            const SizedBox(height: 16),
            Text(
              product.name.split('(').first.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: product.isSubscription ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.formattedPrice,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: product.isSubscription ? Colors.white : primary,
              ),
            ),
            if (product.isSubscription)
              const Text(
                "/ month",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<DonationProvider>(
      builder: (context, provider, child) {
        return TextButton(
          onPressed: provider.isLoading ? null : () => provider.restorePurchases(),
          child: Text(
            "Restore Purchases",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }
}
