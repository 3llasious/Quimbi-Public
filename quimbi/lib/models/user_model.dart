class UserModel {
  final int id;
  final String name;
  final String? gender;
  final String? phone;
  final String? dateOfBirth;

  const UserModel({
    required this.id,
    required this.name,
    this.gender,
    this.phone,
    this.dateOfBirth,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      gender: map['gender'] as String?,
      phone: map['phone'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'phone': phone,
      'date_of_birth': dateOfBirth,
    };
  }
}
