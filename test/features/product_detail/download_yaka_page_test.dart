import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/features/downloads/data/datasources/downloads_remote_data_source.dart';
import 'package:yaka2/features/downloads/data/services/download_manager_service.dart';
import 'package:yaka2/features/downloads/domain/entities/download_manager_item.dart';
import 'package:yaka2/features/downloads/presentation/bloc/download_manager_bloc.dart';
import 'package:yaka2/features/home/domain/entities/collar_entity.dart';
import 'package:yaka2/features/home/domain/repositories/home_repository.dart';
import 'package:yaka2/features/home/presentation/bloc/balance/balance_bloc.dart';
import 'package:yaka2/features/payment/data/datasources/payment_status_remote_data_source.dart';
import 'package:yaka2/features/payment/presentation/bloc/payment_status_bloc.dart';
import 'package:yaka2/features/product_detail/domain/repositories/product_detail_repository.dart';
import 'package:yaka2/features/product_detail/presentation/bloc/product_detail_bloc.dart';
import 'package:yaka2/features/product_detail/presentation/pages/download_yaka_page.dart';

void main() {
  testWidgets(
    'download page keeps machine actions readable on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      final storage = _TestStorage();
      final detailBloc = ProductDetailBloc(_DetailRepository());
      final balanceBloc = BalanceBloc(_HomeRepository());
      final paymentBloc = PaymentStatusBloc(
        remote: const PaymentStatusRemoteDataSource(
          baseUrl: 'https://example.com',
        ),
        storage: storage,
      );
      final downloadsBloc = DownloadManagerBloc(
        service: _DownloadService(storage),
      );
      addTearDown(() async {
        await detailBloc.close();
        await balanceBloc.close();
        await paymentBloc.close();
        await downloadsBloc.close();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.lightTheme,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: detailBloc),
              BlocProvider.value(value: balanceBloc),
              BlocProvider.value(value: paymentBloc),
              BlocProvider.value(value: downloadsBloc),
            ],
            child: const DownloadYakaPage(
              id: 8,
              image: '',
              pageName: 'Gül ýaka',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Elýeterli maşyn görnüşleri'), findsOneWidget);
      expect(find.text('Uzyn maşyn görnüşiniň ady'), findsOneWidget);
      expect(find.text('12.50 TMT'), findsOneWidget);
      expect(find.text('Ýüklendi'), findsOneWidget);
      expect(find.text('Ýükle'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}

class _DetailRepository implements ProductDetailRepository {
  @override
  Future<Result<CollarEntity>> getCollarById(int id) async => const Success(
    CollarEntity(
      id: 8,
      name: 'Gül ýaka',
      files: [
        CollarFileEntity(
          id: 1,
          machineName: 'Uzyn maşyn görnüşiniň ady',
          price: 1250,
        ),
        CollarFileEntity(id: 2, machineName: 'Toyota', purchased: true),
      ],
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HomeRepository implements HomeRepository {
  @override
  double? get cachedBalance => 30;

  @override
  Future<Result<double>> getUserBalance({bool forceRefresh = true}) async =>
      const Success(30);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DownloadService extends DownloadManagerService {
  _DownloadService(LocalStorage storage)
    : super(
        remote: const DownloadsRemoteDataSource(
          baseUrl: 'https://example.com',
          tokenProvider: _noToken,
        ),
        storage: storage,
      );

  @override
  List<DownloadManagerItem> loadCachedItems() => const [];
}

Future<String?> _noToken() async => null;

class _TestStorage extends LocalStorage {
  @override
  bool? get paymentDisabled => false;
}
