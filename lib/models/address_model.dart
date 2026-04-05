class AddressModel {
  final int? id;
  final String houseNo;
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  // 🔥 NAYA: Coordinates add kiye
  final double? latitude;
  final double? longitude;

  AddressModel({
    this.id,
    required this.houseNo,
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      houseNo: json['house_no'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      // 🔥 NAYA: Json se coordinates nikalna
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_no': houseNo,
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      // 🔥 NAYA: Backend ko bhejte waqt
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}