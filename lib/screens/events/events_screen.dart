// lib/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Event> _events = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _userRole;
  DateTime? _lastEventTime;
  final int _limit = 10; // Smaller batch size for pagination

  @override
  void initState() {
    super.initState();
    _loadInitialEvents();
    _loadUserRole();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialEvents() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final newEvents = await EventService.getEvents(limit: _limit);
      setState(() {
        _events = newEvents;
        _isLoading = false;
        if (newEvents.isNotEmpty) {
          _lastEventTime = newEvents.last.startTime;
        }
        _hasMore = newEvents.length == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Failed to load events: $e');
    }
  }

  Future<void> _loadUserRole() async {
    final role = await AuthService.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final newEvents = await EventService.getEvents(
        limit: _limit,
        beforeTime: _lastEventTime,
      );

      setState(() {
        _events.addAll(newEvents);
        _isLoading = false;
        if (newEvents.isNotEmpty) {
          _lastEventTime = newEvents.last.startTime;
        }
        _hasMore = newEvents.length == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Failed to load more events: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMoreEvents();
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _events = [];
      _lastEventTime = null;
      _hasMore = true;
    });
    await _loadInitialEvents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.primaryColorLight),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      floatingActionButton: _userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventScreen()),
                );

                if (result == true) {
                  _refreshEvents();
                }
              },
              child: Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      body: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: _refreshEvents,
        child: _events.isEmpty && !_isLoading
            ? Center(
                child: Text('No events found',
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color)))
            : ListView.builder(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: _events.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _events.length) {
                    return _buildLoader(theme);
                  }
                  return EventCard(
                    event: _events[index],
                    theme: theme,
                    onRefresh: _refreshEvents,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLoader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final ThemeData theme;
  final VoidCallback? onRefresh; // Add this line

  const EventCard({required this.event, required this.theme, this.onRefresh});

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool get _isEventOngoing {
    final now = DateTime.now();
    return now.isAfter(event.startTime) && now.isBefore(event.endTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        // In EventsScreen, modify where you navigate to EventDetailScreen:
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );

          if (result == true && onRefresh != null) {
            onRefresh!(); // Call the refresh callback
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isEventOngoing)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColorLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.primaryColor),
                      ),
                      child: Text(
                        'LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                event.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    event.location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: theme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    '${_formatDate(event.startTime)} - ${_formatDate(event.endTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEventOngoing
                      ? theme.primaryColor
                      : theme.primaryColorLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Fluttertoast.showToast(
                    msg: 'Added "${event.name}" to your calendar',
                    backgroundColor: theme.primaryColor,
                    textColor: theme.primaryColorLight,
                  );
                },
                child: Text(
                  _isEventOngoing ? 'Join Now' : 'Attend',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
