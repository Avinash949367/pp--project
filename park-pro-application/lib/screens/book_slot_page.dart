import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'slot_selection_page.dart';

class BookSlotPage extends StatefulWidget {
  const BookSlotPage({super.key});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  List<dynamic> _stations = [];
  List<dynamic> _filteredStations = [];
  Map<String, List<dynamic>> _slotsMap = {};
  Map<String, double> _ratingsMap = {};
  Map<String, List<dynamic>> _stationsByCity = {};
  List<String> _cities = [];
  String _selectedCity = 'All Cities';
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, bool> _favoriteStatus = {};
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _loadUserToken();
    _fetchStations();
    _searchController.addListener(_filterStations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userToken = prefs.getString('token');
    });
  }

  Future<void> _fetchStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Backend base URL - update this if needed
    const String backendBaseUrl = 'http://localhost:5000/api';

    final url = '$backendBaseUrl/stations';

    print('Fetching stations from $url'); // Debug log

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}'); // Debug log
      print('Raw response body: ${response.body}'); // Detailed raw response log
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data: $data'); // Debug log

        setState(() {
          _stations = data;
          _filteredStations = data;
          final Set<String> uniqueCities = {'All Cities'};
          _stationsByCity = {};
          for (var station in data) {
            final city = station['city']?.toString();
            if (city != null && city.isNotEmpty) {
              uniqueCities.add(city);
              if (_stationsByCity[city] == null) {
                _stationsByCity[city] = [];
              }
              _stationsByCity[city]!.add(station);
            }
            // Check favorite status for each station
            final stationId = station['_id'] ?? station['id'];
            if (stationId != null) {
              _checkFavoriteStatus(stationId);
            }
          }
          _cities = uniqueCities.toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load stations: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching stations: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<dynamic> baseStations = _selectedCity == 'All Cities'
          ? _stations
          : _stationsByCity[_selectedCity] ?? [];
      _filteredStations = baseStations.where((station) {
        final stationName =
            (station['stationName'] ?? station['name'] ?? '').toLowerCase();
        return stationName.contains(query);
      }).toList();
    });
  }

  String _calculateHourlyRate(String stationId) {
    if (_slotsMap.containsKey(stationId)) {
      // For simplicity, take the minimum price among slots as hourly rate
      final slots = _slotsMap[stationId]!;
      if (slots.isNotEmpty) {
        double minPrice = double.infinity;
        for (var slot in slots) {
          if (slot['price'] != null) {
            double price = 0.0;
            try {
              price = double.parse(slot['price'].toString());
            } catch (e) {
              price = 0.0;
            }
            if (price < minPrice) {
              minPrice = price;
            }
          }
        }
        if (minPrice != double.infinity) {
          return '\${minPrice.toStringAsFixed(2)} / hr';
        }
      }
    }
    return '-';
  }

  Future<void> _checkFavoriteStatus(String stationId) async {
    if (_userToken == null) return;

    try {
      String backendUrl;
      if (kIsWeb) {
        backendUrl = 'http://localhost:5000/api/favorites/check/$stationId';
      } else if (Platform.isAndroid) {
        backendUrl = 'http://10.0.2.2:5000/api/favorites/check/$stationId';
      } else if (Platform.isIOS) {
        backendUrl = 'http://localhost:5000/api/favorites/check/$stationId';
      } else {
        backendUrl = 'http://localhost:5000/api/favorites/check/$stationId';
      }

      final response = await http.get(
        Uri.parse(backendUrl),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _favoriteStatus[stationId] = data['isFavorite'] ?? false;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite(String stationId) async {
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    final isCurrentlyFavorite = _favoriteStatus[stationId] ?? false;

    try {
      String backendUrl;
      if (kIsWeb) {
        backendUrl = isCurrentlyFavorite
            ? 'http://localhost:5000/api/favorites/$stationId'
            : 'http://localhost:5000/api/favorites/add';
      } else if (Platform.isAndroid) {
        backendUrl = isCurrentlyFavorite
            ? 'http://10.0.2.2:5000/api/favorites/$stationId'
            : 'http://10.0.2.2:5000/api/favorites/add';
      } else if (Platform.isIOS) {
        backendUrl = isCurrentlyFavorite
            ? 'http://localhost:5000/api/favorites/$stationId'
            : 'http://localhost:5000/api/favorites/add';
      } else {
        backendUrl = isCurrentlyFavorite
            ? 'http://localhost:5000/api/favorites/$stationId'
            : 'http://localhost:5000/api/favorites/add';
      }

      final response = isCurrentlyFavorite
          ? await http.delete(
              Uri.parse(backendUrl),
              headers: {'Authorization': 'Bearer $_userToken'},
            )
          : await http.post(
              Uri.parse(backendUrl),
              headers: {
                'Authorization': 'Bearer $_userToken',
                'Content-Type': 'application/json',
              },
              body: json.encode({'stationId': stationId}),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _favoriteStatus[stationId] = !isCurrentlyFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFavorite
                ? 'Removed from favorites'
                : 'Added to favorites'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorite status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Building BookSlotPage with ${_stations.length} stations'); // Debug print
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Slot'),
        backgroundColor: const Color(0xFF2979FF),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedCity,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue!;
                  _filterStations();
                });
              },
              items: _cities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
              hint: const Text('Select City'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search parking stations...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _filterStations,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: $_errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        ),
                      )
                    : _filteredStations.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? 'No stations found matching your search.'
                                  : 'No stations found.',
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredStations.length,
                            itemBuilder: (context, index) {
                              final station = _filteredStations[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              station['stationName'] ??
                                                  station['name'] ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  (_favoriteStatus[station[
                                                                  '_id'] ??
                                                              station['id']] ??
                                                          false)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: (_favoriteStatus[
                                                              station['_id'] ??
                                                                  station[
                                                                      'id']] ??
                                                          false)
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                                onPressed: () {
                                                  final stationId =
                                                      station['_id'] ??
                                                          station['id'];
                                                  if (stationId != null) {
                                                    _toggleFavorite(stationId);
                                                  }
                                                },
                                                tooltip: (_favoriteStatus[
                                                            station['_id'] ??
                                                                station[
                                                                    'id']] ??
                                                        false)
                                                    ? 'Remove from favorites'
                                                    : 'Add to favorites',
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[100],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'OPEN NOW',
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        station['address'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.attach_money,
                                                  color: Colors.orange),
                                              const SizedBox(width: 4),
                                              Text(
                                                station['id'] != null
                                                    ? _calculateHourlyRate(
                                                        station['id'])
                                                    : '-',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                station['id'] != null &&
                                                        _ratingsMap[station[
                                                                'id']] !=
                                                            null
                                                    ? '${_ratingsMap[station['id']]!.toStringAsFixed(1)}/5'
                                                    : 'N/A',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  color: Colors.brown),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${station['distance']?.toStringAsFixed(1) ?? '-'} miles',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (station['Security'] != null ||
                                              station['security'] != null)
                                            Row(
                                              children: const [
                                                Text('🔒 Security'),
                                                SizedBox(width: 8),
                                              ],
                                            ),
                                          if (station['EV Charging'] != null ||
                                              station['ev_charging'] != null)
                                            Row(
                                              children: const [
                                                Text('⚡ EV Charging'),
                                                SizedBox(width: 8),
                                              ],
                                            ),
                                          if (station['Accessible'] != null ||
                                              station['accessible'] != null)
                                            Row(
                                              children: const [
                                                Text('♿ Accessible'),
                                                SizedBox(width: 8),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final stationId = station['id'];
                                            final slots =
                                                _slotsMap[stationId] ?? [];
                                            print(
                                                'Passing slots to SlotSelectionPage: $slots');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SlotSelectionPage(
                                                        station: station,
                                                        slots: slots),
                                              ),
                                            );
                                          },
                                          child: const Text('Book'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
