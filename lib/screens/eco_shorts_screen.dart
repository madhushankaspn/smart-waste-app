import 'package:flutter/material.dart';

class EcoShortsScreen extends StatefulWidget {
  const EcoShortsScreen({super.key});

  @override
  State<EcoShortsScreen> createState() => _EcoShortsScreenState();
}

class _EcoShortsScreenState extends State<EcoShortsScreen> {
  final List<Map<String, String>> _videos = [
    {
      "title": "How to recycle plastic bottles ♻️",
      "user": "@EcoWarrior",
      "likes": "12.4K",
      "comments": "342",
      "image":
          "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=1000&auto=format&fit=crop",
    },
    {
      "title": "Sorting glass waste easily 🍾",
      "user": "@GreenLife",
      "likes": "8.2K",
      "comments": "120",
      "image":
          "https://images.unsplash.com/photo-1604187351574-c75ca79f5807?q=80&w=1000&auto=format&fit=crop",
    },
    {
      "title": "Making compost at home 🌱",
      "user": "@NatureLover",
      "likes": "21.1K",
      "comments": "890",
      "image":
          "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=1000&auto=format&fit=crop",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical Scroll
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return _buildVideoPlayerUI(_videos[index]);
            },
          ),

          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Eco Shorts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerUI(Map<String, String> videoData) {
    return Stack(
      fit: StackFit.expand,
      children: [
        //  Thumbnail
        Image.network(videoData["image"]!, fit: BoxFit.cover),

        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        //  Play Button
        Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
        ),

        //  (Title, User)
        Positioned(
          bottom: 40,
          left: 20,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                videoData["user"]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                videoData["title"]!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Original Sound - ${videoData["user"]}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        //  (Like, Comment, Share)
        Positioned(
          bottom: 40,
          right: 10,
          child: Column(
            children: [
              _buildSideAction(
                Icons.favorite,
                videoData["likes"]!,
                Colors.redAccent,
              ),
              const SizedBox(height: 20),
              _buildSideAction(
                Icons.comment,
                videoData["comments"]!,
                Colors.white,
              ),
              const SizedBox(height: 20),
              _buildSideAction(Icons.share, "Share", Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideAction(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 35),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
