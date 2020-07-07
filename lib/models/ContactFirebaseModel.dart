class ContactFirebaseModel{

  String contactId;
  String contactName;
  String contactPhoto;
  String contactToken;
  bool isChecked;


  String get getContactId => contactId;
  set setContactId(String value) => contactId = value;

  String get getContactName => contactName;
  set setContactName(String value) => contactName = value;

  String get getContactPhoto => contactPhoto;
  set setContactPhoto(String value) => contactPhoto = value;

  String get getContactToken => contactToken;
  set setContactToken(String value) => contactToken = value;

  bool get getIsChecked => isChecked;
  set setIsChecked(bool value) => isChecked = value;

//  ContactFirebaseModel({
//    this.contactId,
//    this.contactName,
//    this.isChecked,
//  });

//  String get _contactId{
//    return contactId;
//  }
//  set _contactId(String value){
//    contactId = value;
//  }
//
//  String get _contactName{
//    return contactName;
//  }
//  set _contactName(String value){
//    contactName = value;
//  }
//
//  bool get _isChecked{
//    return isChecked;
//  }
//  set _isChecked(bool value) {
//    if(value==null) {
//      throw new ArgumentError();
//    }
//    isChecked = value;
//  }

}