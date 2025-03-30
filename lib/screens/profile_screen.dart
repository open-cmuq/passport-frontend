// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;
  final UserService _userService = UserService();
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late User _currentUser;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _gradYearController;
  late TextEditingController _titleController;
  late TextEditingController _biographyController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userFuture = _userService.getCurrentUser().then((user) {
        _currentUser = user;
        _initializeControllers(user);
        return user;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gradYearController.dispose();
    _titleController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  void _initializeControllers(User user) {
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _gradYearController = TextEditingController(text: user.gradYear?.toString() ?? '');
    _titleController = TextEditingController(text: user.title ?? '');
    _biographyController = TextEditingController(text: user.biography ?? '');
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedUser = User(
          id: _currentUser.id,
          name: _nameController.text,
          email: _emailController.text,
          gradYear: int.tryParse(_gradYearController.text),
          title: _titleController.text,
          biography: _biographyController.text,
          photoUrl: _currentUser.photoUrl,
          role: _currentUser.role,
          department: _currentUser.department,
          currentPoints: _currentUser.currentPoints,
          registrationDate: _currentUser.registrationDate,
        );

        await _userService.updateCurrentUser(updatedUser);
        setState(() {
          _isEditing = false;
          _loadUserData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.photoUrl != null 
                  ? NetworkImage(user.photoUrl!) 
                  : null,
              child: user.photoUrl == null 
                  ? Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
              backgroundColor: Colors.grey[300],
            ),
            if (_isEditing)
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 18),
                  color: Colors.white,
                  onPressed: () {
                    // TODO: Implement photo upload
                  },
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          user.title ?? 'No title',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 8),
        Chip(
          label: Text(
            user.role?.toUpperCase() ?? 'USER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getRoleColor(user.role),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red[700]!;
      case 'staff':
        return Colors.blue[700]!;
      case 'student':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    bool isEditable = false,
    TextInputType? keyboardType,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          isEditable
              ? TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: validator,
                )
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.isNotEmpty ? value : 'Not specified',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_isEditing)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _initializeControllers(user);
                    });
                  },
                  child: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: _isEditing ? _saveProfile : () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(User user) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.star, color: Colors.amber),
              ],
            ),
            SizedBox(height: 12),
            Text(
              user.currentPoints?.toString() ?? '0',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Earned through participation in events',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(child: Text('No profile data available'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(user),
                  if (!_isEditing) _buildPointsSection(user),
                  _buildProfileField(
                    label: 'Full Name',
                    value: user.name,
                    isEditable: _isEditing,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  _buildProfileField(
                    label: 'Email',
                    value: user.email ?? 'No email',
                    isEditable: _isEditing,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  _buildProfileField(
                    label: 'Graduation Year',
                    value: user.gradYear?.toString() ?? 'Not specified',
                    isEditable: _isEditing,
                    controller: _gradYearController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      final year = int.tryParse(value);
                      if (year == null) {
                        return 'Please enter a valid year';
                      }
                      if (year < 1900 || year > 2100) {
                        return 'Please enter a realistic year';
                      }
                      return null;
                    },
                  ),
                  _buildProfileField(
                    label: 'Title',
                    value: user.title ?? 'No title',
                    isEditable: _isEditing,
                    controller: _titleController,
                  ),
                  _buildProfileField(
                    label: 'Biography',
                    value: user.biography ?? 'No biography',
                    isEditable: _isEditing,
                    controller: _biographyController,
                    keyboardType: TextInputType.multiline,
                  ),
                  SizedBox(height: 24),
                  _buildActionButtons(user),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
