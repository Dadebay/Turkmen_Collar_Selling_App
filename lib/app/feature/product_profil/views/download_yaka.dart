// ignore_for_file: avoid_slow_async_io

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/models/collar_model.dart';
import 'package:yaka2/app/feature/home/services/collars_service.dart';
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

  Future<int> _getAndroidVersion() async {
    final release = await File('/system/build.prop').readAsLines().then((lines) => lines.firstWhere((line) => line.startsWith('ro.build.version.sdk='), orElse: () => 'ro.build.version.sdk=0'));
    return int.tryParse(release.split('=').last) ?? 0;
  }

  dynamic _initializeDownloadDirectory() async {
    final path1 = Directory('storage/emulated/0/Download');
    final status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    } else if (status.isDenied) {
      await Permission.storage.request();
    }

    if (await path1.exists()) {
      await _createFolder();
      return path1.path;
    } else {
      await _createFolder();
      await path1.create();
      return path1.path;
    }
  }

  Future<String> _createFolder() async {
    final path = Directory('storage/emulated/0/Download/YAKA');
    if (!await path.exists()) {
      await path.create();
    }
    return path.path;
  }

  Future<String> _createFolderForProduct(String machineName) async {
    final path = Directory('storage/emulated/0/Download/YAKA/$machineName/${widget.pageName}');
    if (!path.existsSync()) {
      await path.create(recursive: true);
    }
    return path.path;
  }

  String _extractFileExtension(String filePath) {
    return filePath.split('.').last;
  }

  String _extractFileName(String filePath) {
    return filePath.split('/').last.split('.').first;
  }

  Future<void> _downloadFile(int index) async {
    productProfilController.sany.value = 0;
    productProfilController.totalSum.value = 0;

    final double balance = double.parse(homeController.balance.toString().split('.')[0]);
    final Random rand = Random();

    final String machineName = machineNameList[index].machineName!.toUpperCase();
    final String subPath = 'YAKA/$machineName/${widget.pageName}';

    Get.back();
    DialogUtils.downloadDialog(context);

    if (!machineNameList[index].purchased! && balance <= machineNameList[index].price! / 100) {
      Get.back();
      showSnackBar('noMoney', 'noMoneySubtitle', ColorConstants.redColor);
      return;
    }

    final downloadUrls = await DownloadsService().downloadFile(id: machineNameList[index].id!);
    productProfilController.totalSum.value = downloadUrls.length;

    for (int i = 0; i < downloadUrls.length; i++) {
      final String url = downloadUrls[i];
      final String fileName = url.split('/').last;
      await FileDownloader.downloadFile(
        url: url,
        name: fileName,
        subPath: subPath,
        onProgress: (name, progress) {},
        onDownloadCompleted: (path) {
          productProfilController.sany.value++;

          if (i == downloadUrls.length - 1) {
            _fetchCollarsData();
            Get.back();
            DialogUtils.showDownloadSuccessDialog(context: context);
          }
        },
        onDownloadError: (error) {
          Get.back();
          showSnackBar('errorTitle'.tr, 'Download error: $error', ColorConstants.redColor);
        },
      );
    }

    homeController.userMoney();
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
            machineNameList[index].purchased!
                ? SizedBox.shrink()
                : Expanded(
                    flex: 3,
                    child: CustomWidgets.showProductsPrice(
                      context: context,
                      color: machineNameList[index].purchased! ? ColorConstants.greenColor : ColorConstants.blackColor,
                      makeBigger: false,
                      price: machineNameList[index].price.toString(),
                    ),
                  ),
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
