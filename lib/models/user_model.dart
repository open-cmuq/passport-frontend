class User {
  final int? id;
  final String name;
  final String email;
  final String? photoUrl;
  final int? gradYear;
  final int? currentPoints;
  final String? role;
  final String? department;
  final String? title;
  final String? biography;
  final DateTime? registrationDate;

  User({
    this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.gradYear,
    this.currentPoints,
    this.role,
    this.department,
    this.title,
    this.biography,
    this.registrationDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photo_url'],
      gradYear: json['grad_year'],
      currentPoints: json['current_points'],
      role: json['role'],
      department: json['department'],
      title: json['title'],
      biography: json['biography'],
      registrationDate: json['registration_date'] != null 
          ? DateTime.parse(json['registration_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'grad_year': gradYear,
      'title': title,
      'biography': biography,
      // Include other fields that might be needed for update
      'department': department,
    };
  }
}
