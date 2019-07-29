import 'package:shared_preferences/shared_preferences.dart';

export 'local-storage.dart';

class LocalStorage {
  SharedPreferences _localStorage;

  void init(Function callback) async {
    _localStorage = await SharedPreferences.getInstance();
    callback();
  }

  List<Map<String, double>> getSavedCitiesList() {
    final List<String> savedCitiesLongitude = _localStorage.getStringList('savedCitiesLongitude') ?? [];
    final List<String> savedCitiesLatitude = _localStorage.getStringList('savedCitiesLatitude') ?? [];
    final List<Map<String, double>> savedCitiesList = [];
    Map<String, double> cityObj = {};

    for (int i=0; i<savedCitiesLongitude.length; i++) {
      cityObj['latitude'] = double.parse(savedCitiesLatitude[i]);
      cityObj['longitude'] = double.parse(savedCitiesLongitude[i]);
      savedCitiesList.add(cityObj);
    }

    return savedCitiesList;
  }

  void removeFromSavedCitiesList(int index) {
    List<String> savedCitiesLongitude = _localStorage.getStringList('savedCitiesLongitude') ?? [];
    List<String> savedCitiesLatitude = _localStorage.getStringList('savedCitiesLatitude') ?? [];

    savedCitiesLongitude.removeAt(index);
    savedCitiesLatitude.removeAt(index);

    _localStorage.setStringList('savedCitiesLongitude', savedCitiesLongitude);
    _localStorage.setStringList('savedCitiesLatitude', savedCitiesLatitude);
  }

  void addToSavedCitiesList(double latitude, double longitude) {
    List<String> savedCitiesLongitude = _localStorage.getStringList('savedCitiesLongitude') ?? [];
    List<String> savedCitiesLatitude = _localStorage.getStringList('savedCitiesLatitude') ?? [];

    savedCitiesLongitude.add(longitude.toString());
    savedCitiesLatitude.add(latitude.toString());

    _localStorage.setStringList('savedCitiesLongitude', savedCitiesLongitude);
    _localStorage.setStringList('savedCitiesLatitude', savedCitiesLatitude);
  }

  bool getIsCelsius() {
    return _localStorage.getBool('isCelsius') ?? true;
  }

  void toggleIsCelsius() {
    bool isCelsius = getIsCelsius();
    _localStorage.setBool('isCelsius', !isCelsius);
  }
}