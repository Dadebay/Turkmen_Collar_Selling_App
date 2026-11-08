import 'package:get_it/get_it.dart';

import 'core/constants/api_constants.dart';
import 'core/services/account_remote_data_source.dart';
import 'core/services/sms_otp_service.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/send_otp_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/data/datasources/cart_local_data_source.dart';
import 'features/cart/data/datasources/cart_remote_data_source.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/downloads/data/datasources/downloads_remote_data_source.dart';
import 'features/downloads/data/services/download_manager_service.dart';
import 'features/downloads/data/services/file_export_service.dart';
import 'features/downloads/data/services/usb_storage_service.dart';
import 'features/downloads/presentation/bloc/download_manager_bloc.dart';
import 'features/downloads/presentation/bloc/usb_transfer/usb_transfer_bloc.dart';
import 'features/favorites/data/datasources/favorites_local_data_source.dart';
import 'features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/domain/repositories/favorites_repository.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
import 'features/home/data/datasources/home_remote_data_source.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/presentation/bloc/balance/balance_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/bloc/show_all_products/show_all_products_bloc.dart';
import 'features/payment/data/datasources/payment_status_remote_data_source.dart';
import 'features/payment/data/datasources/payment_transaction_remote_data_source.dart';
import 'features/payment/data/datasources/phone_payment_limit_remote_data_source.dart';
import 'features/payment/presentation/bloc/payment_status_bloc.dart';
import 'features/product_detail/data/datasources/product_detail_remote_data_source.dart';
import 'features/product_detail/data/repositories/product_detail_repository_impl.dart';
import 'features/product_detail/domain/repositories/product_detail_repository.dart';
import 'features/product_detail/presentation/bloc/product_detail_bloc.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/user_profile/data/datasources/history_orders_remote_data_source.dart';
import 'features/user_profile/data/datasources/profile_meta_remote_data_source.dart';
import 'features/user_profile/data/datasources/search_by_image_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // --- Storage ---
  sl.registerLazySingleton<LocalStorage>(() => LocalStorage());

  // --- Data Sources ---
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => const AuthRemoteDataSource(baseUrl: ApiConstants.baseUrl),
  );
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  // Single source of truth for `GET /api/v1/users/me` (auth validation,
  // wallet balance, profile) — shared across features.
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      localStorage: sl(),
    ),
  );
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSource(sl()),
  );
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSource(sl()),
  );
  sl.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<ProductDetailRemoteDataSource>(
    () => ProductDetailRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<DownloadsRemoteDataSource>(
    () => DownloadsRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<ProfileMetaRemoteDataSource>(
    () => ProfileMetaRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<HistoryOrdersRemoteDataSource>(
    () => HistoryOrdersRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<PaymentStatusRemoteDataSource>(
    () => const PaymentStatusRemoteDataSource(baseUrl: ApiConstants.baseUrl),
  );
  sl.registerLazySingleton<PhonePaymentLimitRemoteDataSource>(
    () => PhonePaymentLimitRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );
  sl.registerLazySingleton<PaymentTransactionRemoteDataSource>(
    () =>
        const PaymentTransactionRemoteDataSource(baseUrl: ApiConstants.baseUrl),
  );
  sl.registerLazySingleton<SearchByImageRemoteDataSource>(
    () => SearchByImageRemoteDataSource(
      baseUrl: ApiConstants.baseUrl,
      tokenProvider: () async => sl<LocalStorage>().token,
    ),
  );

  // --- Services ---
  sl.registerLazySingleton<DownloadManagerService>(
    () => DownloadManagerService(remote: sl(), storage: sl()),
  );
  sl.registerLazySingleton<UsbStorageService>(() => UsbStorageService());
  sl.registerLazySingleton<FileExportService>(() => const FileExportService());
  sl.registerLazySingleton<SmsOtpService>(() => SmsOtpService());

  // --- Repositories ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(local: sl(), remote: sl(), account: sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remote: sl(), account: sl(), local: sl()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(local: sl(), remote: sl()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(local: sl(), remote: sl()),
  );
  sl.registerLazySingleton<ProductDetailRepository>(
    () => ProductDetailRepositoryImpl(sl()),
  );

  // --- Use Cases ---
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // --- BLoCs (factories — new instance per page) ---
  sl.registerFactory(
    () => AuthBloc(
      repository: sl(),
      sendOtp: sl(),
      verifyOtp: sl(),
      logout: sl(),
    ),
  );
  sl.registerFactory(() => HomeBloc(sl()));
  sl.registerFactory(() => BalanceBloc(sl()));
  sl.registerFactory(() => ShowAllProductsBloc(sl()));
  sl.registerFactory(() => CartBloc(sl()));
  sl.registerFactory(() => FavoritesBloc(sl()));
  sl.registerFactory(() => ProductDetailBloc(sl()));
  sl.registerFactory(() => SearchBloc(sl()));

  // DownloadManagerBloc is a singleton so the progress ribbon and any
  // download UI share the same active-downloads map.
  sl.registerLazySingleton<DownloadManagerBloc>(
    () => DownloadManagerBloc(service: sl()),
  );

  // PaymentStatusBloc is app-wide: wallet visibility, download/cart fallback,
  // and add-money guards all read from it.
  sl.registerLazySingleton<PaymentStatusBloc>(
    () => PaymentStatusBloc(remote: sl(), storage: sl()),
  );

  sl.registerFactory<UsbTransferBloc>(
    () => UsbTransferBloc(
      usbStorage: sl(),
      downloadManager: sl(),
      downloadManagerBloc: sl(),
    ),
  );
}
