import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_background.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  Future<String>? _loadPrivacyPolicyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPrivacyPolicyFuture ??= DefaultAssetBundle.of(context).loadString('assets/docs/privacy_policy.md');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Privacy Policy",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: _loadPrivacyPolicyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading privacy policy",
                    style: TextStyle(color: primary),
                  ),
                );
              }

              return Markdown(
                data: snapshot.data ?? "",
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.5,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: AppTheme.fontFamily,
                    height: 2.0,
                  ),
                  p: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.6,
                  ),
                  listBullet: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                  strong: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: primary.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(24),
              );
            },
          ),
        ),
      ),
    );
  }
}
