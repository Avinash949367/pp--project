import 'package:flutter/material.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Use final instead of const
  final Color darkGray = const Color(0xFF1E1E1E);
  final Color electricBlue = const Color(0xFF2979FF);

  List<Map<String, dynamic>> favoriteSpots = [
    {
      'id': '1',
      'name': 'Downtown Parking',
      'address': '123 Main St, City Center',
      'pricePerHour': 5.99,
      'distance': 0.8,
      'rating': 4.5,
      'totalSpots': 45,
      'availableSpots': 12,
      'isFavorite': true,
    },
    {
      'id': '2',
      'name': 'Mall Parking',
      'address': '456 Shopping Ave, Mall Area',
      'pricePerHour': 4.50,
      'distance': 1.2,
      'rating': 4.2,
      'totalSpots': 200,
      'availableSpots': 45,
      'isFavorite': true,
    },
    {
      'id': '3',
      'name': 'Riverfront Parking',
      'address': '789 River Rd, Waterfront',
      'pricePerHour': 6.75,
      'distance': 2.1,
      'rating': 4.8,
      'totalSpots': 30,
      'availableSpots': 5,
      'isFavorite': true,
    },
  ];

  void _removeFromFavorites(Map<String, dynamic> spot) {
    setState(() {
      favoriteSpots.removeWhere((element) => element['id'] == spot['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${spot['name']} from favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAllFavorites() {
    setState(() {
      favoriteSpots.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All favorites cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        actions: [
          if (favoriteSpots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllFavorites,
              tooltip: 'Clear all favorites',
            ),
        ],
      ),
      body: favoriteSpots.isEmpty ? _buildEmptyState() : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the heart icon to add parking spots to favorites',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('Find Parking Spots'),
            style: ElevatedButton.styleFrom(
              backgroundColor: electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${favoriteSpots.length} favorite parking ${favoriteSpots.length == 1 ? 'spot' : 'spots'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: favoriteSpots.length,
            itemBuilder: (context, index) {
              final spot = favoriteSpots[index];
              return _buildFavoriteItem(spot);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> spot) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spot['name'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: electricBlue),
                  onPressed: () => _removeFromFavorites(spot),
                  tooltip: 'Remove from favorites',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spot['address'],
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  icon: Icons.attach_money,
                  text: '\$${spot['pricePerHour']}/h',
                  color: Colors.greenAccent,
                ),
                _buildInfoChip(
                  icon: Icons.directions_car,
                  text: '${spot['availableSpots']} available',
                  color: (spot['availableSpots'] as int) > 5 ? electricBlue : Colors.orange,
                ),
                _buildInfoChip(
                  icon: Icons.star,
                  text: spot['rating'].toString(),
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToBooking(spot),
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(Map<String, dynamic> spot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${spot['name']}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
