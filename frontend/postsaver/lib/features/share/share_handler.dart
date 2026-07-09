import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/auth/auth_provider.dart';
import 'share_provider.dart';

class ShareHandler extends ConsumerStatefulWidget {
  final Widget child;

  const ShareHandler({super.key, required this.child});

  @override
  ConsumerState<ShareHandler> createState() => _ShareHandlerState();
}

class _ShareHandlerState extends ConsumerState<ShareHandler> {
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialIntent();
    _listenForForegroundIntents();
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialIntent() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media.isNotEmpty) {
      _processSharedContent(media);
    }
  }

  void _listenForForegroundIntents() {
    _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (media) {
        if (media.isNotEmpty) {
          _processSharedContent(media);
        }
      },
      onError: (error) {
        debugPrint('Error receiving share intent: $error');
      },
    );
  }

  void _processSharedContent(List<SharedMediaFile> media) {
    for (final file in media) {
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        _processSharedText(file.path);
        return;
      }
    }
  }

  void _processSharedText(String text) {
    final url = _extractUrl(text);
    if (url == null) return;

    final authState = ref.read(authStateProvider);
    if (authState != AuthState.authenticated) {
      ref.read(sharedUrlProvider.notifier).setUrl(url);
      return;
    }

    _navigateToCreatePost(url);
  }

  String? _extractUrl(String text) {
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    if (text.contains('.') && !text.contains(' ')) {
      return 'https://$text';
    }

    return null;
  }

  void _navigateToCreatePost(String url) {
    final encodedUrl = Uri.encodeComponent(url);
    context.go('/posts/new?url=$encodedUrl');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
