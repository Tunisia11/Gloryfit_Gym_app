import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_cubit.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/post/post_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/Dashbord.dart';
import 'package:gloryfit_version_3/screens/posts/post_detail_screen.dart';
import 'package:gloryfit_version_3/screens/profile/widgets/post_grid_tile.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch posts specific to this user when the screen loads
    context.read<PostCubit>().fetchPostsByUserId(widget.user.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(context),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.red.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.red.shade700,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.fitness_center)),
                      Tab(icon: Icon(Icons.bar_chart)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsGrid(),
              _buildWorkoutsSection(),
              _buildStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            CircleAvatar(
              radius: 45,
              backgroundImage: widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.user.photoURL!)
                  : null,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 12),
            Text(
              widget.user.displayName ?? "User",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    // This is where you would fetch real data for followers, etc.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
         BlocBuilder<PostCubit, PostState>(
          builder: (context, state) {
             if(state is PostLoaded){
               return _buildStatColumn(state.posts.length.toString(), "Posts");
             }
             return _buildStatColumn("0", "Posts");
           },
         ),
        _buildStatColumn("5", "Workouts"),
        _buildStatColumn("253", "Followers"),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Edit Profile"),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () {
            context.read<AuthCubit>().signOut();
            // Pop all routes until back to the login/auth wrapper
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Sign Out"),
        ),
        if (widget.user.role == UserRole.admin) ...[
           const SizedBox(width: 12),
          IconButton(onPressed: (){
                Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
          }, icon: const Icon(Icons.admin_panel_settings_outlined))
        ]
      ],
    );
  }

  Widget _buildPostsGrid() {
    return BlocBuilder<PostCubit, PostState>(
      builder: (context, state) {
        if (state is PostLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PostLoaded) {
          if (state.posts.isEmpty) {
            return const Center(child: Text("No posts yet."));
          }
          return RefreshIndicator(
            onRefresh: () async {
               context.read<PostCubit>().fetchPostsByUserId(widget.user.id);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return PostGridTile(
                  post: post,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<PostCubit>(),
                          child: PostDetailScreen(post: post),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }
        if (state is PostError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text("Your posts will appear here."));
      },
    );
  }

  Widget _buildWorkoutsSection() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Text("Workout history coming soon!"),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Text("Detailed fitness stats coming soon!"),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
