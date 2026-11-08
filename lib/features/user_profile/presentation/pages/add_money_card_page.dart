// ignore_for_file: always_put_control_body_on_new_line
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../features/payment/data/datasources/payment_transaction_remote_data_source.dart';
import '../../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../../../../injection_container.dart';
import 'add_money_page.dart' show OnlineAddMoneyToWallet;
import '../../../../core/icons/app_icon.dart';

class AddMoneyCardPage extends StatefulWidget {
  const AddMoneyCardPage({super.key});

  @override
  State<AddMoneyCardPage> createState() => _AddMoneyCardPageState();
}

class _AddMoneyCardPageState extends State<AddMoneyCardPage> {
  int value = 0;
  String number = '';

  final List<int> moneyList = const [20, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    number = sl<LocalStorage>().phone ?? '';
  }

  Future<void> _submit() async {
    final paymentsDisabled = context.read<PaymentStatusBloc>().state.isDisabled;
    if (paymentsDisabled) {
      showSnackBar(
        context,
        'notWork',
        'notWorkSubtitle',
        ColorConstants.redColor,
      );
      context.pop();
      return;
    }
    final token = sl<LocalStorage>().token;
    if (token == null || token.isEmpty) {
      showSnackBar(
        context,
        'loginError',
        'loginErrorSubtitle1',
        ColorConstants.redColor,
      );
      return;
    }
    final amount = '${moneyList[value]}';
    final result = await sl<PaymentTransactionRemoteDataSource>()
        .sendTransactionSMS(sender: number, amount: amount);
    if (!mounted) return;
    if (result is Success<String>) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              OnlineAddMoneyToWallet(url: result.dataOrThrow, amount: amount),
        ),
      );
    } else {
      showSnackBar(
        context,
        'errorTitle',
        'paymentInitiationFailed',
        ColorConstants.redColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'addCash',
        showBackButton: true,
        actionButton: IconButton(
          onPressed: () async {
            if (number.isEmpty) return;
            await launchUrlString('tel://$number');
          },
          icon: AppIcon(
            IconlyLight.call,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: ListView(
        padding: context.padding.normal,
        children: [
          Row(
            children: [
              Text(
                'myNumber'.tr,
                style: context.general.textTheme.titleLarge!.copyWith(
                  color: AppPalette.of(context).muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  number,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.general.textTheme.titleLarge!.copyWith(
                    color: AppPalette.of(context).text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: context.padding.verticalMedium,
            child: Text(
              'addMoneyTitle1'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.titleLarge!.copyWith(
                color: ColorConstants.redColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: List.generate(
                moneyList.length,
                (index) => InkWell(
                  onTap: () => setState(() => value = index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: value,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: ColorConstants.primaryColor,
                        onChanged: (int? ind) =>
                            setState(() => value = ind ?? 0),
                      ),
                      Text(
                        '${moneyList[index]} TMT',
                        style: TextStyle(
                          color: AppPalette.of(context).text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AgreeButton(text: 'onlinePayment', onTap: _submit),
        ],
      ),
    );
  }
}
