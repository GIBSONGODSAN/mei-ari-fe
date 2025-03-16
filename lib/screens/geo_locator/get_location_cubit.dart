import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';

part 'get_location_state.dart';

class GetLocationCubit extends Cubit<GetLocationState> {
  GetLocationCubit() : super(GetLocationInitial());

  static GetLocationCubit get(context) => BlocProvider.of(context);

  late Position position;
  late Placemark place;

  initLocation() async {
    bool isServiceEnabled;
    LocationPermission permission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();

    if (!isServiceEnabled) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('denied forever');
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('denied');
      }
    }
  }

  Future<Position> getLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
          this.position = position;
        })
        .catchError((error) {});
    return position;
  }

  Future<Placemark?> getCountry() async {
    emit(LocationLoading());

    try {
      Position? loc = await getLocation();

      List<Placemark> places = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );

      if (places.isNotEmpty) {
        place = places[0];
        emit(LocationSuccess());
        return place;
      } else {
        emit(LocationFail("No location found."));
        return null;
      }
    } catch (error) {
      emit(LocationFail("Error fetching location: $error"));
      return null;
    }
  }
}
