// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this import
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({this.userId, Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;
  final UserService _userService = UserService();
  bool _isEditing = false;
  bool _isCurrentUser = false;
  final _formKey = GlobalKey<FormState>();
  late User _currentUser;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _gradYearController;
  late TextEditingController _titleController;
  late TextEditingController _biographyController;
  late TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    _checkIfCurrentUser();
    _loadUserData();
  }

  void _checkIfCurrentUser() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      setState(() {
        _isCurrentUser =
            widget.userId == null || widget.userId == currentUser.id.toString();
      });
    } catch (e) {
      setState(() {
        _isCurrentUser = false;
      });
    }
  }

  void _loadUserData() {
    setState(() {
      _userFuture = widget.userId != null
          ? _userService.getUser(widget.userId!)
          : _userService.getCurrentUser().then((user) {
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
    _departmentController.dispose();
    super.dispose();
  }

  void _initializeControllers(User user) {
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _gradYearController = TextEditingController(
      text: user.gradYear?.toString() ?? '',
    );
    _titleController = TextEditingController(text: user.title ?? '');
    _biographyController = TextEditingController(text: user.biography ?? '');
    _departmentController = TextEditingController(text: user.department ?? '');
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
          gradYear: int.tryParse(_gradYearController.text),
          title: _titleController.text,
          biography: _biographyController.text,
          department: _departmentController.text,
          // Preserve existing fields
          email: _currentUser.email,
          photoUrl: _currentUser.photoUrl,
          role: _currentUser.role,
          currentPoints: _currentUser.currentPoints,
          registrationDate: _currentUser.registrationDate,
        );

        await _userService.updateUserProfile(updatedUser);
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

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Security Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: null, // TODO
          child: Text('Change Email Address'),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: null, // TODO
          child: Text('Change Password'),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
              backgroundColor: Colors.grey[300],
            ),
            if (_isEditing && _isCurrentUser)
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 18),
                  color: Colors.white,
                  onPressed: () {/* TODO: Photo upload */},
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
    int? maxLines,
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
                  maxLines: maxLines,
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
    if (!_isCurrentUser) return SizedBox.shrink();

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
              onPressed: _isEditing
                  ? _saveProfile
                  : () {
                      setState(() => _isEditing = true);
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
    if (!_isCurrentUser) return SizedBox.shrink();

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

  Widget _buildQrCodeSection(User user) {
    if (!_isCurrentUser || _isEditing) return SizedBox.shrink();

    final qrData = 'user:${user.id}:${user.email}';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Your QR Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Scan this code to share your profile',
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

  Widget _buildProfileInformationSection(User user) {
    // Don't show profile details for current user unless editing
    if (_isCurrentUser && !_isEditing) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileField(
              label: 'Full Name',
              value: user.name,
              isEditable: _isEditing && _isCurrentUser,
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            if (_isCurrentUser)
              _buildProfileField(
                label: 'Email',
                value: user.email ?? 'No email',
                isEditable: false,
              ),
            _buildProfileField(
              label: 'Department',
              value: user.department ?? 'Not specified',
              isEditable: _isEditing && _isCurrentUser,
              controller: _departmentController,
            ),
            _buildProfileField(
              label: 'Graduation Year',
              value: user.gradYear?.toString() ?? 'Not specified',
              isEditable: _isEditing && _isCurrentUser,
              controller: _gradYearController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final year = int.tryParse(value);
                if (year == null) return 'Invalid year';
                if (year < 1900 || year > 2100) return 'Invalid year range';
                return null;
              },
            ),
            _buildProfileField(
              label: 'Title',
              value: user.title ?? 'No title',
              isEditable: _isEditing && _isCurrentUser,
              controller: _titleController,
            ),
            _buildProfileField(
              label: 'Biography',
              value: user.biography ?? 'No biography',
              isEditable: _isEditing && _isCurrentUser,
              controller: _biographyController,
              maxLines: 3,
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
        title: Text(_isCurrentUser ? 'My Profile' : 'User Profile'),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load profile',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No profile data available'));
          }

          final user = snapshot.data!;
          if (widget.userId == null) _currentUser = user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  _buildPointsSection(user),
                  _buildQrCodeSection(user),
                  _buildProfileInformationSection(user),
                  if (_isCurrentUser && _isEditing) _buildSecuritySection(),
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
