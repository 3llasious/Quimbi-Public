class PersonModel {
  final int id;
  final String name;
  final String? phone;
  final String? contactId;

  const PersonModel({
    required this.id,
    required this.name,
    this.phone,
    this.contactId,
  });

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      contactId: map['contact_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'contact_id': contactId,
    };
  }
}
