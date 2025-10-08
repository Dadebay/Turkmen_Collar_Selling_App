
import 'package:upgrader/upgrader.dart';

class UpgraderMessagesTR extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'Soňra';

  @override
  String get buttonTitleLater => 'Soňra';

  @override
  String get buttonTitleUpdate => 'Täzele';

  @override
  String get prompt => 'Programmanyň täze wersiýasy bar. Ony ýükläp bilersiňiz.';

  @override
  String get title => 'Täze wersiýa';
}

class UpgraderMessagesRU extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'Позже';

  @override
  String get buttonTitleLater => 'Позже';

  @override
  String get buttonTitleUpdate => 'Обновить';

  @override
  String get prompt => 'Доступна новая версия приложения. Вы можете скачать ее.';

  @override
  String get title => 'Новая версия';
}
