// lib/screens/posts/story_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloryfit_version_3/models/story_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryViewerScreen extends StatefulWidget {
  final Map<String, List<StoryModel>> groupedStories;
  final String initialUserId;

  const StoryViewerScreen({
    super.key,
    required this.groupedStories,
    required this.initialUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    final userIds = widget.groupedStories.keys.toList();
    _currentUserIndex = userIds.indexOf(widget.initialUserId);

    _pageController = PageController(initialPage: _currentUserIndex);
    _animationController = AnimationController(vsync: this);

    _loadStory(animateToPage: false);

    // This hides the system UI for a full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    // **FIXED**: This reliably restores the system UI, including the bottom navigation bar.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _loadStory({bool animateToPage = true}) {
    if (!mounted) return;
    _animationController.stop();
    _animationController.reset();

    _animationController.duration = const Duration(seconds: 8);
    _animationController.forward().whenComplete(_next);

    if (animateToPage) {
      _pageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    if (!mounted) return;
    final userIds = widget.groupedStories.keys.toList();
    final currentUserStories = widget.groupedStories[userIds[_currentUserIndex]]!;

    if (_currentStoryIndex < currentUserStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _loadStory(animateToPage: false);
    } else if (_currentUserIndex < userIds.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _loadStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (!mounted) return;
    final userIds = widget.groupedStories.keys.toList();

    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _loadStory(animateToPage: false);
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex =
            widget.groupedStories[userIds[_currentUserIndex]]!.length - 1;
      });
      _loadStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _pauseStory() => _animationController.stop();
  void _resumeStory() {
    if (!mounted) return;
    _animationController.forward().whenComplete(_next);
  }

  @override
  Widget build(BuildContext context) {
    final userIds = widget.groupedStories.keys.toList();
    if (userIds.isEmpty || _currentUserIndex >= userIds.length) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }
    final stories = widget.groupedStories[userIds[_currentUserIndex]]!;
    if (stories.isEmpty || _currentStoryIndex >= stories.length) {
       return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }
    final story = stories[_currentStoryIndex];

    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx > screenWidth / 2) {
          _next();
        } else {
          _previous();
        }
      },
      onLongPressStart: (_) => _pauseStory(),
      onLongPressEnd: (_) => _resumeStory(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: story.mediaUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.error, color: Colors.white)),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: SafeArea(
                child: Row(
                  children: List.generate(stories.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            double value = 0.0;
                            if (index < _currentStoryIndex) {
                              value = 1.0;
                            } else if (index == _currentStoryIndex) {
                              value = _animationController.value;
                            }
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withOpacity(0.4),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 2.5,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(story.userImage)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [Shadow(blurRadius: 5)]),
                          ),
                          Text(
                            timeago.format(story.createdAt, locale: 'en_short'),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                shadows: const [Shadow(blurRadius: 5)]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, shadows: [Shadow(blurRadius: 5)]),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
