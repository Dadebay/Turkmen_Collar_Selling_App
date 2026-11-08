import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/product_detail/presentation/bloc/product_detail_bloc.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../injection_container.dart';

import '../../features/auth/presentation/pages/force_update_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/pages/order_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/domain/entities/category_entity.dart';
import '../../features/home/domain/entities/product_entity.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/show_all_products_page.dart';
import '../../features/product_detail/presentation/pages/product_detail_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/user_profile/presentation/pages/user_profile_page.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/user_profile/presentation/pages/downloaded_page.dart';
import '../../features/home/presentation/pages/instruction_page.dart';
import '../../features/home/presentation/pages/video_player_page.dart';
import '../../features/home/presentation/pages/banner_detail_page.dart';
import '../../features/home/presentation/pages/photo_gallery_page.dart';
import '../../features/product_detail/presentation/pages/download_yaka_page.dart';
import '../../features/product_detail/presentation/pages/photo_view_page.dart';
import '../../features/user_profile/presentation/pages/about_us_page.dart';
import '../../features/user_profile/presentation/pages/add_money_card_page.dart';
import '../../features/user_profile/presentation/pages/add_money_page.dart';
import '../../features/user_profile/presentation/pages/add_money_phone_page.dart';
import '../../features/user_profile/presentation/pages/copy_to_usb_page.dart';
import '../../features/user_profile/presentation/pages/faq_page.dart';
import '../../features/user_profile/presentation/pages/history_orders_page.dart';
import '../../features/user_profile/presentation/pages/profil_settings_page.dart';
import '../../features/user_profile/presentation/pages/search_by_image_page.dart';
import '../../features/user_profile/presentation/pages/usb_transfer_page.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp/:phone';
  static const forceUpdate = '/force-update';
  static const home = '/home';
  static const cart = '/cart';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const productDetail = '/product/:id';
  static const showAllProducts = '/products/:category';
  static const search = '/search';
  static const aiChat = '/ai-chat';
  static const downloads = '/downloads';
  static const instruction = '/instruction';
  static const order = '/order';
  static const photoView = '/photo-view';
  static const photoGallery = '/photo-gallery';
  static const videoPlayer = '/video-player';
  static const downloadYaka = '/download-yaka/:id';
  static const addMoney = '/add-money';
  static const addMoneyCard = '/add-money/card';
  static const addMoneyPhone = '/add-money/phone';
  static const copyToUsb = '/copy-to-usb';
  static const usbTransfer = '/usb-transfer';
  static const searchByImage = '/search-by-image';
  static const bannerDetail = '/banner';
  static const historyOrders = '/profile/orders';
  static const aboutUs = '/profile/about';
  static const faq = '/profile/faq';
  static const profilSettings = '/profile/settings';

  static String productDetailPath(int id, {bool isCollar = false}) =>
      '/product/$id${isCollar ? '?isCollar=1' : ''}';
  static String showAllProductsPath(
    String category, {
    int? subCatId,
    int? subCatIndex,
  }) {
    final query = <String, String>{};
    if (subCatId != null) {
      query['subCatId'] = '$subCatId';
    }
    if (subCatIndex != null) {
      query['subCatIndex'] = '$subCatIndex';
    }
    final qs = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '/products/$category$qs';
  }

  static String otpPath(String phone) => '/otp/$phone';
  static String downloadYakaPath(int id) => '/download-yaka/$id';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) {
        final phone = state.pathParameters['phone'] ?? '';
        return OtpPage(phoneNumber: Uri.decodeComponent(phone));
      },
    ),
    GoRoute(
      path: AppRoutes.forceUpdate,
      builder: (_, __) => const ForceUpdatePage(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        // Bottom-nav tabs switch instantly (no page transition) — the
        // standard behaviour for tab navigation. Pushed/detail routes still
        // use the Material transition configured in the app theme.
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (_, state) => const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: AppRoutes.cart,
          pageBuilder: (_, state) => const NoTransitionPage(child: CartPage()),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          pageBuilder: (_, state) =>
              const NoTransitionPage(child: FavoritesPage()),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (_, state) =>
              const NoTransitionPage(child: UserProfilePage()),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final product = state.extra as ProductEntity?;
        final isCollarQuery = state.uri.queryParameters['isCollar'] == '1';
        return BlocProvider<ProductDetailBloc>(
          create: (_) => sl<ProductDetailBloc>(),
          child: ProductDetailPage(
            productId: id,
            product: product,
            isCollar: isCollarQuery,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.showAllProducts,
      builder: (context, state) {
        final category = state.pathParameters['category'] ?? '';
        final categoryEntity = state.extra as CategoryEntity?;
        final query = state.uri.queryParameters;
        return ShowAllProductsPage(
          category: category,
          categoryEntity: categoryEntity,
          subCatId: int.tryParse(query['subCatId'] ?? ''),
          subCatIndex: int.tryParse(query['subCatIndex'] ?? ''),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (context, state) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          child: BlocProvider<SearchBloc>(
            create: (_) => sl<SearchBloc>(),
            child: const SearchPage(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.23, 1, 0.32, 1),
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: reduceMotion ? Offset.zero : const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(path: AppRoutes.aiChat, builder: (_, __) => const AiChatPage()),
    GoRoute(
      path: AppRoutes.downloads,
      builder: (_, __) => const DownloadedPage(),
    ),
    GoRoute(
      path: AppRoutes.instruction,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return InstructionPage(initialTab: (extra?['initialTab'] as int?) ?? 0);
      },
    ),
    GoRoute(path: AppRoutes.order, builder: (_, __) => const OrderPage()),
    GoRoute(
      path: AppRoutes.photoView,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PhotoViewPage(
          image: extra?['image'] as String?,
          networkImage: (extra?['networkImage'] as bool?) ?? true,
          shouldShowWaterMark: extra?['shouldShowWaterMark'] as bool? ?? true,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.photoGallery,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PhotoGalleryPage(
          images: (extra?['images'] as List?)?.cast<String>() ?? const [],
          title: extra?['title'] as String?,
          initialIndex: (extra?['initialIndex'] as int?) ?? 0,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.videoPlayer,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return VideoPlayerPage(
          videoPath: (extra?['videoPath'] as String?) ?? '',
          appBarTitle: (extra?['appBarTitle'] as String?) ?? '',
          cacheKey: extra?['cacheKey'] as String?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.downloadYaka,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final extra = state.extra as Map<String, dynamic>?;
        return BlocProvider<ProductDetailBloc>(
          create: (_) => sl<ProductDetailBloc>(),
          child: DownloadYakaPage(
            id: id,
            image: (extra?['image'] as String?) ?? '',
            pageName: (extra?['pageName'] as String?) ?? '',
          ),
        );
      },
    ),
    GoRoute(path: AppRoutes.addMoney, builder: (_, __) => const AddMoneyPage()),
    GoRoute(
      path: AppRoutes.addMoneyCard,
      builder: (_, __) => const AddMoneyCardPage(),
    ),
    GoRoute(
      path: AppRoutes.addMoneyPhone,
      builder: (_, state) => AddMoneyPhonePage(
        amount: state.extra is int ? state.extra as int : 20,
      ),
    ),
    GoRoute(
      path: AppRoutes.copyToUsb,
      builder: (_, __) => const CopyToUsbPage(),
    ),
    GoRoute(
      path: AppRoutes.usbTransfer,
      builder: (_, __) => const UsbTransferPage(),
    ),
    GoRoute(
      path: AppRoutes.searchByImage,
      builder: (_, __) => const SearchByImagePage(),
    ),
    GoRoute(
      path: AppRoutes.historyOrders,
      builder: (_, __) => const HistoryOrdersPage(),
    ),
    GoRoute(path: AppRoutes.aboutUs, builder: (_, __) => const AboutUsPage()),
    GoRoute(path: AppRoutes.faq, builder: (_, __) => const FaqPage()),
    GoRoute(
      path: AppRoutes.profilSettings,
      builder: (_, __) => const ProfilSettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.bannerDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return BannerDetailPage(
          pageName: extra?['pageName'] ?? '',
          image: extra?['image'] ?? '',
          description: extra?['description'] ?? '',
        );
      },
    ),
  ],
);
