// lib/screens/newWorkoutSystemScreens/live_workout_screen.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:gloryfit_version_3/screens/newWorkoutSystemScreens/workout_summary_screen.dart';
import 'package:video_player/video_player.dart';

// --- UI Style Constants ---
const TextStyle _kTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1);
const TextStyle _kSubtitleStyle = TextStyle(
    color: Color(0xFF64B5F6), fontSize: 18, fontWeight: FontWeight.bold);
const TextStyle _kTimerLabelStyle =
    TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500);
const TextStyle _kTimerValueStyle =
    TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold);

/// **NEW ARCHITECTURE**: A dedicated class to manage the lifecycle of the VideoPlayerController.
/// This isolates the complex video logic, preventing state management issues in the UI.
class VideoManager {
  VideoPlayerController? _controller;
  String? _currentUrl;
  bool _isDisposed = false;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  VideoPlayerController? get controller => _controller;

  /// Loads a new video from a URL.
  /// It correctly disposes of the old controller before creating a new one.
  Future<bool> loadVideo(String url) async {
    if (_isDisposed) return false;
    if (_currentUrl == url && isInitialized) return true;
    
    await dispose();
    _currentUrl = url;

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      // **FIX**: Mute the video by default.
      await _controller!.setVolume(0.0);
      await _controller!.setLooping(true);
      if (_isDisposed) {
        await dispose();
        return false;
      }
      return true;
    } catch (e) {
      print('--- VIDEO LOAD ERROR for $url: $e');
      _controller = null;
      return false;
    }
  }

  Future<void> play() async {
    if (isInitialized && !isPlaying) {
      await _controller!.play();
    }
  }

  Future<void> pause() async {
    if (isInitialized && isPlaying) {
      await _controller!.pause();
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _currentUrl = null;
  }
  
  void markAsDisposed() {
    _isDisposed = true;
  }
}

/// Main workout screen rebuilt with the new VideoManager architecture.
class LiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  const LiveWorkoutScreen({super.key, required this.workout});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late final VideoManager _videoManager;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  WorkoutExercise? _currentExerciseForVideo;
  int _currentExerciseIndex = -1;
  bool _isVideoReady = false;
  bool _isWorkoutPaused = false;
  
  Timer? _totalWorkoutTimer;
  int _totalTimeInSeconds = 0;
  
  // **FIX**: Local timer for rest countdown.
  Timer? _restCountdownTimer;
  int _restTimeRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _videoManager = VideoManager();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    
    _setupInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoManager.markAsDisposed();
    _videoManager.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _totalWorkoutTimer?.cancel();
    _restCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _videoManager.pause();
        _stopAllTimers();
        break;
      case AppLifecycleState.resumed:
        if (!_isWorkoutPaused) {
          _videoManager.play();
          _startTotalTimer();
        }
        break;
      default:
        break;
    }
  }
  
  // --- Timer Management ---
  void _startTotalTimer() {
    _totalWorkoutTimer?.cancel();
    _totalWorkoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isWorkoutPaused) {
        setState(() {
          _totalTimeInSeconds++;
        });
      }
    });
  }
  
  void _stopAllTimers() {
    _totalWorkoutTimer?.cancel();
    _restCountdownTimer?.cancel();
  }

  void _startRestCountdown(int duration) {
    _restCountdownTimer?.cancel();
    setState(() => _restTimeRemaining = duration);
    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 1) {
        setState(() => _restTimeRemaining--);
      } else {
        timer.cancel();
        if (mounted && context.read<WorkoutCubit>().state is WorkoutResting) {
          context.read<WorkoutCubit>().resumeWorkout();
        }
      }
    });
  }

  // --- State & Video Setup ---
  void _setupInitialState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<WorkoutCubit>().state;
      if (state is WorkoutInProgress) {
        final exerciseIndex = _getActiveExerciseIndex(state.progress);
        if (exerciseIndex != -1) {
          _updateCurrentExerciseVideo(state.workout.exercises[exerciseIndex], exerciseIndex);
        }
        _totalTimeInSeconds = state.totalTimeInSeconds;
        _startTotalTimer();
      }
    });
  }

  int _getActiveExerciseIndex(WorkoutProgress progress) {
    return progress.exercises.indexWhere((e) => !e.isCompleted);
  }
  
  Future<void> _updateCurrentExerciseVideo(WorkoutExercise newExercise, int newIndex) async {
    if (!mounted || _currentExerciseIndex == newIndex) return;
    
    _currentExerciseForVideo = newExercise;
    _currentExerciseIndex = newIndex;
    
    _fadeController.reset();
    setState(() => _isVideoReady = false);

    if (newExercise.videoUrl != null && newExercise.videoUrl!.isNotEmpty) {
      final success = await _videoManager.loadVideo(newExercise.videoUrl!);
      if (mounted && success) {
        setState(() => _isVideoReady = true);
        if (!_isWorkoutPaused) _videoManager.play();
        _fadeController.forward();
      }
    } else {
      await _videoManager.dispose();
      _fadeController.forward();
    }
  }

  // --- Event Handlers ---
  void _onPlayPause() {
    HapticFeedback.lightImpact();
    if (_isWorkoutPaused) {
      context.read<WorkoutCubit>().resumeWorkout();
    } else {
      context.read<WorkoutCubit>().pauseWorkout();
    }
  }

  void _onSetCompleted() {
    HapticFeedback.mediumImpact();
    context.read<WorkoutCubit>().completeSet();
  }

  void _onSkipRest() {
    _restCountdownTimer?.cancel();
    HapticFeedback.lightImpact();
    context.read<WorkoutCubit>().skipRest();
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // --- Main Build & State Handling ---
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocListener<WorkoutCubit, WorkoutState>(
          listener: _handleStateChange,
          child: BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, state) {
              if (state is WorkoutInProgress) {
                return _buildExerciseUI(state, isPaused: false);
              }
              if (state is WorkoutPaused) {
                return _buildExerciseUI(state, isPaused: true);
              }
              if (state is WorkoutResting) {
                return _buildRestUI(state);
              }
              return const _LoadingView();
            },
          ),
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, WorkoutState state) {
    if (!mounted) return;
    _restCountdownTimer?.cancel();

    if (state is WorkoutCompleted) {
      _videoManager.dispose();
      _stopAllTimers();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(workout: state.workout, progress: state.progress)),
      );
      return;
    }
    
    _isWorkoutPaused = state is WorkoutPaused;
    if (_isWorkoutPaused) {
      _videoManager.pause();
      _stopAllTimers();
    } else {
       _videoManager.play();
       _startTotalTimer();
    }

    if (state is WorkoutInProgress) {
      final newExerciseIndex = _getActiveExerciseIndex(state.progress);
      if (newExerciseIndex != -1 && newExerciseIndex != _currentExerciseIndex) {
        _updateCurrentExerciseVideo(state.workout.exercises[newExerciseIndex], newExerciseIndex);
      }
    } else if (state is WorkoutResting) {
        _stopAllTimers();
        _totalTimeInSeconds = state.totalTimeInSeconds; // Sync total time
        _startRestCountdown(state.restTimeRemaining);
    }
  }

  // --- UI Builder Methods ---
  Widget _buildExerciseUI(dynamic state, {required bool isPaused}) {
    final progress = state.progress as WorkoutProgress;
    final workout = state.workout as Workout;

    final activeExerciseIndex = _getActiveExerciseIndex(progress);
    if (activeExerciseIndex == -1) return const _LoadingView();
    
    final currentExerciseForBuild = workout.exercises[activeExerciseIndex];
    final exerciseProgress = progress.exercises[activeExerciseIndex];
    final setIndex = exerciseProgress.sets.indexWhere((s) => !s.isCompleted);
    final displaySetIndex = setIndex > -1 ? setIndex : (exerciseProgress.sets.isNotEmpty ? exerciseProgress.sets.length - 1 : 0);

    return SafeArea(
      child: Column(
        children: [
          Expanded(flex: 3, child: _buildMediaView()),
          Expanded(
            flex: 2,
            child: _buildControlsView(currentExerciseForBuild, displaySetIndex, isPaused),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_currentExerciseForVideo?.id),
        width: double.infinity,
        color: Colors.black,
        child: FadeTransition(
          opacity: _fadeController,
          child: _isVideoReady && _videoManager.isInitialized
              ? Center(child: AspectRatio(
                  aspectRatio: _videoManager.controller!.value.aspectRatio,
                  child: VideoPlayer(_videoManager.controller!),
                ))
              : _OptimizedNetworkImage(imageUrl: _currentExerciseForVideo?.imageUrl ?? ''),
        ),
      ),
    );
  }

  Widget _buildControlsView(WorkoutExercise exercise, int setIndex, bool isPaused) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildExerciseInfo(exercise, setIndex),
          const Spacer(),
          _buildTimerRow(exercise, isPaused),
          const Spacer(),
          _buildCompleteButton(isPaused),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(WorkoutExercise exercise, int setIndex) {
    return Column(
      children: [
        Text(exercise.name.toUpperCase(), style: _kTitleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.05),
            child: Text(
                "SET ${setIndex + 1} / ${exercise.sets}  •  ${exercise.repsPerSet} REPS",
                style: _kSubtitleStyle),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRow(WorkoutExercise exercise, bool isPaused) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _TimeDisplay(label: "TOTAL TIME", time: _formatDuration(_totalTimeInSeconds)),
        _PlayPauseButton(isPaused: isPaused, onPressed: _onPlayPause),
        _TimeDisplay(label: "REST", time: "00:${exercise.restBetweenSetsSeconds.toString().padLeft(2, '0')}"),
      ],
    );
  }

  Widget _buildCompleteButton(bool isPaused) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPaused ? Colors.grey[800] : const Color(0xFF0A84FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: isPaused ? null : _onSetCompleted,
        child: const Text('COMPLETE SET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRestUI(WorkoutResting state) {
    final nextExerciseIndex = _getActiveExerciseIndex(state.progress);
    final nextExercise = nextExerciseIndex != -1 ? state.workout.exercises[nextExerciseIndex] : null;

    final lastCompletedExerciseIndex = state.progress.exercises.lastIndexWhere((e) => e.isCompleted);
    final restDuration = lastCompletedExerciseIndex != -1 
        ? state.workout.exercises[lastCompletedExerciseIndex].restBetweenSetsSeconds
        : 60;

    return Stack(
      fit: StackFit.expand,
      children: [
        _RestBackground(imageUrl: nextExercise?.imageUrl),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                      onPressed: _onSkipRest,
                      icon: const Icon(Icons.fast_forward, color: Colors.white),
                      label: const Text("SKIP", style: TextStyle(color: Colors.white))),
                ),
              ),
              // **FIX**: Now uses the local rest timer variable.
              _RestTimer(timeRemaining: _restTimeRemaining, totalRestTime: restDuration),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: Text(
                    "NEXT UP: ${nextExercise?.name.toUpperCase() ?? 'Workout Complete'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        )
      ],
    );
  }
}

// --- Helper & UI Component Widgets ---

class _PlayPauseButton extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPressed;
  const _PlayPauseButton({required this.isPaused, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (isPaused ? Colors.green : const Color(0xFF0A84FF)).withOpacity(0.4), blurRadius: 15, spreadRadius: 3)],
      ),
      child: IconButton(
        icon: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: isPaused ? Colors.greenAccent : const Color(0xFF0A84FF),
          size: 72,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final String label;
  final String time;
  const _TimeDisplay({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Text(label, style: _kTimerLabelStyle), const SizedBox(height: 8), Text(time, style: _kTimerValueStyle)],
    );
  }
}

class _RestBackground extends StatelessWidget {
  final String? imageUrl;
  const _RestBackground({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null) _OptimizedNetworkImage(imageUrl: imageUrl!),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }
}

class _RestTimer extends StatelessWidget {
  final int timeRemaining;
  final int totalRestTime;
  const _RestTimer({required this.timeRemaining, required this.totalRestTime});

  @override
  Widget build(BuildContext context) {
    final progress = timeRemaining / (totalRestTime > 0 ? totalRestTime : 1);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
          Center(
            child: Text(timeRemaining.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final Widget fallback;
  const _OptimizedNetworkImage({required this.imageUrl, this.fallback = const _ExercisePlaceholder()});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _ExercisePlaceholder extends StatelessWidget {
  const _ExercisePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(child: Icon(Icons.fitness_center, color: Colors.white24, size: 80)),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF0A84FF)),
          SizedBox(height: 20),
          Text("Preparing Workout...", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
