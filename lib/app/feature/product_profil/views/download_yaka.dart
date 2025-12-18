// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/models/collar_model.dart';
import 'package:yaka2/app/feature/home/services/collars_service.dart';
import 'package:yaka2/app/feature/payment/controllers/payment_status_controller.dart';
import 'package:yaka2/app/feature/product_profil/controllers/product_profil_controller.dart';
import 'package:yaka2/app/feature/product_profil/views/photo_view.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

class DownloadYakaPage extends StatefulWidget {
  final int id;
  final String image;
  final String pageName;
  const DownloadYakaPage({
    required this.image,
    required this.pageName,
    required this.id,
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadYakaPage> createState() => _DownloadYakaPageState();
}

class _DownloadYakaPageState extends State<DownloadYakaPage> {
  final BalanceController homeController = Get.find();
  final ProductProfilController productProfilController = Get.put(ProductProfilController());
  final PaymentStatusController paymentStatusController = Get.find();
  List<FilesModel> machineNameList = [];

  @override
  void initState() {
    super.initState();
    _fetchCollarsData();
    _initializeDownloadDirectory();
    homeController.userMoney();
  }

  void _fetchCollarsData() async {
    machineNameList = (await CollarService().getCollarsByID(widget.id)).files ?? [];
    setState(() {});
  }

  dynamic _initializeDownloadDirectory() async {
    print('🔵 [DOWNLOAD] Initializing download directory...');
    print('🔵 [DOWNLOAD] Platform: ${Platform.isIOS ? "iOS" : "Android"}');

    if (Platform.isIOS) {
      // iOS: Use Documents directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        print('✅ [DOWNLOAD] iOS Documents directory: ${directory.path}');
        await _createFolder();
        return directory.path;
      } catch (e) {
        print('❌ [DOWNLOAD] Error getting iOS directory: $e');
        rethrow;
      }
    } else {
      // Android: Use existing Download folder logic
      final path1 = Directory('storage/emulated/0/Download');
      final status = await Permission.storage.status;

      print('🔵 [DOWNLOAD] Android storage permission status: $status');

      if (!status.isGranted) {
        print('🔵 [DOWNLOAD] Requesting storage permission...');
        await Permission.storage.request();
      } else if (status.isDenied) {
        print('⚠️ [DOWNLOAD] Storage permission denied, requesting again...');
        await Permission.storage.request();
      }

      if (await path1.exists()) {
        print('✅ [DOWNLOAD] Android Download directory exists: ${path1.path}');
        await _createFolder();
        return path1.path;
      } else {
        print('⚠️ [DOWNLOAD] Creating Android Download directory...');
        await _createFolder();
        await path1.create();
        return path1.path;
      }
    }
  }

  Future<String> _createFolder() async {
    print('🔵 [DOWNLOAD] Creating YAKA folder...');

    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final path = Directory('${directory.path}/YAKA');
      print('🔵 [DOWNLOAD] iOS YAKA folder path: ${path.path}');

      if (!await path.exists()) {
        await path.create();
        print('✅ [DOWNLOAD] iOS YAKA folder created');
      } else {
        print('✅ [DOWNLOAD] iOS YAKA folder already exists');
      }
      return path.path;
    } else {
      final path = Directory('storage/emulated/0/Download/YAKA');
      print('🔵 [DOWNLOAD] Android YAKA folder path: ${path.path}');

      if (!await path.exists()) {
        await path.create();
        print('✅ [DOWNLOAD] Android YAKA folder created');
      } else {
        print('✅ [DOWNLOAD] Android YAKA folder already exists');
      }
      return path.path;
    }
  }

  // ignore: unused_element
  // This function is kept for potential future use when manual folder creation is needed
  Future<String> _createFolderForProduct(String machineName) async {
    print('🔵 [DOWNLOAD] Creating product folder for: $machineName/${widget.pageName}');

    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final path = Directory('${directory.path}/YAKA/$machineName/${widget.pageName}');
      print('🔵 [DOWNLOAD] iOS product folder path: ${path.path}');

      if (!path.existsSync()) {
        await path.create(recursive: true);
        print('✅ [DOWNLOAD] iOS product folder created');
      } else {
        print('✅ [DOWNLOAD] iOS product folder already exists');
      }
      return path.path;
    } else {
      final path = Directory('storage/emulated/0/Download/YAKA/$machineName/${widget.pageName}');
      print('🔵 [DOWNLOAD] Android product folder path: ${path.path}');

      if (!path.existsSync()) {
        await path.create(recursive: true);
        print('✅ [DOWNLOAD] Android product folder created');
      } else {
        print('✅ [DOWNLOAD] Android product folder already exists');
      }
      return path.path;
    }
  }

  Future<void> _downloadFile(int index) async {
    print('🟢 [DOWNLOAD] ========== DOWNLOAD STARTED ==========');
    print('🟢 [DOWNLOAD] Product index: $index');
    print('🟢 [DOWNLOAD] Product name: ${widget.pageName}');
    print('🟢 [DOWNLOAD] Machine name: ${machineNameList[index].machineName}');

    productProfilController.sany.value = 0;
    productProfilController.totalSum.value = 0;

    final double balance = double.parse(homeController.balance.toString());

    final String machineName = machineNameList[index].machineName!.toUpperCase();
    final String subPath = 'YAKA/$machineName/${widget.pageName}';

    print('🔵 [DOWNLOAD] SubPath: $subPath');
    print('🔵 [DOWNLOAD] User balance: $balance');

    Get.back();
    DialogUtils.downloadDialog(context);

    // Check payment status - if disabled, skip balance check and purchase flow
    final bool isPaymentDisabled = paymentStatusController.isPaymentDisabled.value;

    if (!isPaymentDisabled) {
      // Payment enabled - check balance for unpurchased items
      if (!machineNameList[index].purchased! && balance < machineNameList[index].price! / 100) {
        print('❌ [DOWNLOAD] Insufficient balance');
        Get.back();
        showSnackBar('noMoney', 'noMoneySubtitle', ColorConstants.redColor);
        return;
      }
    } else {
      // Payment disabled - only allow downloading purchased items
      if (!machineNameList[index].purchased!) {
        print('❌ [DOWNLOAD] Payment disabled - only purchased items can be downloaded');
        Get.back();
        showSnackBar('errorTitle'.tr, 'Bu özellik şu anda kullanılamıyor.', ColorConstants.redColor);
        return;
      }
      print('✅ [DOWNLOAD] Payment disabled but item is already purchased - allowing download');
    }

    print('🔵 [DOWNLOAD] Fetching download URLs from server...');
    final downloadUrls = await DownloadsService().downloadFile(id: machineNameList[index].id!);
    productProfilController.totalSum.value = downloadUrls.length;
    print('✅ [DOWNLOAD] Received ${downloadUrls.length} file URLs');

    for (int i = 0; i < downloadUrls.length; i++) {
      final String url = downloadUrls[i];
      String fileName = url.split('/').last;

      // Fix duplicate extensions (e.g., "file.jef.jef" -> "file.jef")
      final parts = fileName.split('.');
      if (parts.length > 2 && parts[parts.length - 1] == parts[parts.length - 2]) {
        // Remove the last duplicate extension
        fileName = parts.sublist(0, parts.length - 1).join('.');
        print('🔧 [DOWNLOAD] Fixed duplicate extension: ${url.split('/').last} -> $fileName');
      }

      print('🔵 [DOWNLOAD] File ${i + 1}/${downloadUrls.length}: $fileName');
      print('🔵 [DOWNLOAD] URL: $url');

      if (Platform.isIOS) {
        // iOS: Use Dio for downloading
        try {
          final directory = await getApplicationDocumentsDirectory();
          final savePath = '${directory.path}/$subPath/$fileName';

          print('🔵 [DOWNLOAD] iOS save path: $savePath');

          // Create directory if it doesn't exist
          final saveDir = Directory('${directory.path}/$subPath');
          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
            print('✅ [DOWNLOAD] Created directory: ${saveDir.path}');
          }

          final dio = Dio();
          await dio.download(
            url,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final progress = (received / total * 100).toInt();
                if (progress % 25 == 0) {
                  print('📊 [DOWNLOAD] Progress for $fileName: $progress%');
                }
              }
            },
          );

          productProfilController.sany.value++;
          print('✅ [DOWNLOAD] File completed: $fileName');
          print('✅ [DOWNLOAD] Saved to: $savePath');
          print('✅ [DOWNLOAD] Progress: ${productProfilController.sany.value}/${productProfilController.totalSum.value}');

          if (i == downloadUrls.length - 1) {
            print('🎉 [DOWNLOAD] All files downloaded successfully!');
            _fetchCollarsData();
            Get.back();
            DialogUtils.showDownloadSuccessDialog(context: context);
          }
        } catch (e) {
          print('❌ [DOWNLOAD] Error downloading $fileName: $e');
          Get.back();
          showSnackBar('errorTitle'.tr, 'Download error: $e', ColorConstants.redColor);
          return;
        }
      } else {
        // Android: Use flutter_file_downloader
        await FileDownloader.downloadFile(
          url: url,
          name: fileName,
          subPath: subPath,
          onProgress: (name, progress) {
            if (progress % 25 == 0) {
              print('📊 [DOWNLOAD] Progress for $name: $progress%');
            }
          },
          onDownloadCompleted: (path) {
            productProfilController.sany.value++;
            print('✅ [DOWNLOAD] File completed: $fileName');
            print('✅ [DOWNLOAD] Saved to: $path');
            print('✅ [DOWNLOAD] Progress: ${productProfilController.sany.value}/${productProfilController.totalSum.value}');

            if (i == downloadUrls.length - 1) {
              print('🎉 [DOWNLOAD] All files downloaded successfully!');
              _fetchCollarsData();
              Get.back();
              DialogUtils.showDownloadSuccessDialog(context: context);
            }
          },
          onDownloadError: (error) {
            print('❌ [DOWNLOAD] Error downloading $fileName: $error');
            Get.back();
            showSnackBar('errorTitle'.tr, 'Download error: $error', ColorConstants.redColor);
          },
        );
      }
    }

    homeController.userMoney();
    print('🟢 [DOWNLOAD] ========== DOWNLOAD PROCESS COMPLETED ==========');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.pageName, showBackButton: true, showWallet: true),
      body: ListView(
        padding: context.padding.onlyBottomHigh,
        children: [
          Container(
            height: Get.size.height / 3,
            margin: context.padding.normal,
            child: GestureDetector(
              onTap: () => Get.to(() => PhotoViewPage(image: widget.image, networkImage: true)),
              child: CustomWidgets.customImageView(image: widget.image, cover: true, borderRadius: CustomBorderRadius.normalBorderRadius),
            ),
          ),
          _collarsListView(context),
        ],
      ),
    );
  }

  Widget _collarsListView(BuildContext context) {
    return ListView.separated(
      itemCount: machineNameList.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: context.padding.normal,
      itemBuilder: (BuildContext context, int index) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 70,
              child: CachedNetworkImage(
                fadeInCurve: Curves.ease,
                imageUrl: machineNameList[index].machineLogo!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: CustomBorderRadius.lowBorderRadius,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => Loading(),
                errorWidget: (context, url, error) => NoImage(),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: context.padding.horizontalLow,
                child: Text(
                  machineNameList[index].machineName ?? 'Yaka',
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: machineNameList[index].purchased! ? ColorConstants.greenColor : ColorConstants.blackColor,
                    fontWeight: machineNameList[index].purchased! ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Hide price if payment is disabled
            Obx(() {
              if (paymentStatusController.isPaymentDisabled.value || machineNameList[index].purchased!) {
                return SizedBox.shrink();
              }
              return Expanded(
                flex: 3,
                child: CustomWidgets.showProductsPrice(
                  context: context,
                  color: ColorConstants.blackColor,
                  makeBigger: false,
                  price: machineNameList[index].price.toString(),
                ),
              );
            }),
            _downloadButton(index, context),
          ],
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: context.padding.low,
          child: Divider(
            thickness: 1,
            color: ColorConstants.blackColor.withOpacity(.3),
          ),
        );
      },
    );
  }

  Expanded _downloadButton(int index, BuildContext context) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          if (machineNameList[index].purchased!) {
            _downloadFile(index);
          } else {
            DialogUtils.askToDownloadYaka(
              index: index,
              context: context,
              downloadYaka: () {
                _downloadFile(index);
              },
            );
          }
        },
        child: Container(
          margin: context.padding.verticalLow,
          padding: context.padding.low,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: machineNameList[index].purchased! ? ColorConstants.greenColor : ColorConstants.primaryColor, borderRadius: context.border.lowBorderRadius),
          child: machineNameList[index].purchased!
              ? Text(
                  'downloadedYAKA'.tr,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  'download'.tr,
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
