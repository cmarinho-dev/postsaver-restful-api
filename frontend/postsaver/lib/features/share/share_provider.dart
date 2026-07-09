import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/social_source.dart';

class SharedUrlState {
  final String? sharedUrl;
  final bool isProcessing;

  const SharedUrlState({this.sharedUrl, this.isProcessing = false});

  SharedUrlState copyWith({String? sharedUrl, bool? isProcessing, bool clearUrl = false}) {
    return SharedUrlState(
      sharedUrl: clearUrl ? null : (sharedUrl ?? this.sharedUrl),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class SharedUrlNotifier extends StateNotifier<SharedUrlState> {
  SharedUrlNotifier() : super(const SharedUrlState());

  void setUrl(String url) {
    state = state.copyWith(sharedUrl: url);
  }

  void clearUrl() {
    state = state.copyWith(clearUrl: true);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }
}

final sharedUrlProvider = StateNotifierProvider<SharedUrlNotifier, SharedUrlState>((ref) {
  return SharedUrlNotifier();
});

SocialSource inferSocialSource(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return SocialSource.other;

  final host = uri.host.toLowerCase();

  if (host.contains('instagram.com')) return SocialSource.instagram;
  if (host.contains('tiktok.com')) return SocialSource.tiktok;
  if (host.contains('facebook.com')) return SocialSource.facebook;
  if (host.contains('kwai.com')) return SocialSource.kwai;
  if (host.contains('youtube.com')) return SocialSource.youtube;
  if (host.contains('twitter.com') || host.contains('x.com')) return SocialSource.twitter;

  return SocialSource.other;
}
