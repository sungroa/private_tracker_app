import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:private_tracker_app/core/utils/security_logger.dart';
import 'package:private_tracker_app/domain/services/partner_sharing_service.dart';
import 'package:private_tracker_app/presentation/pages/partner_mode_page.dart';
import 'package:provider/provider.dart';

/// Manages application-level lifecycle events and deep links.
///
/// Following "Technical Excellence" principles, this decouples UI-level
/// navigation orchestration from the main App widget.
class AppLifecycleManager extends StatefulWidget {
  const AppLifecycleManager({super.key, required this.child, required this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    try {
      final al = context.read<AppLinks>();
      _linkSubscription = al.uriLinkStream.listen((uri) {
        if (!mounted) return;
        _handleDeepLink(uri);
      });
    } catch (e, stack) {
      SecurityLogger.logError("AppLinks initialization failed", error: e, stackTrace: stack);
    }
  }

  void _handleDeepLink(Uri uri) {
    // Resolve dependency from the nearest context
    final partnerService = context.read<PartnerSharingService>();
    final params = partnerService.parseDeepLink(uri);

    if (params != null) {
      widget.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) =>
              PartnerModePage(initialPayload: params['data'], initialKey: params['key']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
