//можео будет удалить попозже

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../data/datasources/routes_remote_ds.dart';
import '../data/repositories/routes_repository_impl.dart';
import '../domain/repositories/routes_repository.dart';
import '../domain/usecases/create_route.dart';
import '../domain/usecases/get_my_routes.dart';
import '../domain/usecases/toggle_privacy.dart';


// Low-level
final firestoreProvider = Provider((_) => FirebaseFirestore.instance);
final routesRemoteDsProvider = Provider((ref) => RoutesRemoteDataSource(ref.read(firestoreProvider)));
final routesRepoProvider = Provider<IRoutesRepository>((ref) => RoutesRepositoryImpl(ref.read(routesRemoteDsProvider)));


// UseCases
final getMyRoutesProvider = Provider((ref) => GetMyRoutes(ref.read(routesRepoProvider)));
final createRouteProvider = Provider((ref) => CreateRoute(ref.read(routesRepoProvider)));
final togglePrivacyProvider = Provider((ref) => TogglePrivacy(ref.read(routesRepoProvider)));