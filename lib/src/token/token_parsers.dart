import 'package:meta/meta.dart';

import 'token_parser.dart';

/// Russian token parsers.
///
/// In this class you can found many ready-to-use parsers, that you can use with [Hors] class.
/// In many cases all you need to do is use [TokenParsers.all].
/// But you free to use those parsers what you need, or event create your own.
///
/// Table of parsers to symbols:
/// Parser | Symbol
/// -|-
/// "год" | Y
/// название месяца | M
/// название дня недели | D
/// "назад" | b
/// "спустя" | l (lower L)
/// "через" | i
/// "выходной" | W
/// "минута" | e
/// "час" | h
/// "день" | d
/// "неделя" | w
/// "месяц" | m
/// "прошлый", "прошедший", "предыдущий" | s
/// "этот", "текущий", "нынешний" | u
/// "ближайший", "грядущий" | y
/// "следующий", "будущий" | x
/// "послезавтра" | 6
/// "завтра" | 5
/// "сегодня" | 4
/// "вчера" | 3
/// "позавчера" | 2
/// "утро" | r
/// "полдень" | n
/// "вечер" | v
/// "ночь" | g
/// "половина" | H
/// "четверть" | Q
/// "в", "с" | f
/// "до", "по" | t
/// "на" | о
/// "число" | #
/// "и" | N
/// TODO: x
/// число больше 1900 и меньше 9999 | 1
/// неотрицательное число меньше 1901 | 0
/// уже обработанная алгоритмом дата | @
/// любой другой токен | _
@experimental
class TokenParsers {
  const TokenParsers._();

  static const PluralTokenParser after = PluralTokenParser(
    normalForms: ['через'],
    forms: {
      'через': 0,
      'черезо': 0,
      'чрез': 0,
      'чрезо': 0,
    },
    metaSymbol: 'i',
  );

  static const PluralTokenParser afterPostfix = PluralTokenParser(
    normalForms: ['спустя'],
    forms: {
      'спустя': 0,
    },
    metaSymbol: 'l',
  );

  static const PluralTokenParser previousPostfix = PluralTokenParser(
    normalForms: ['назад'],
    forms: {
      'назад': 0,
    },
    metaSymbol: 'b',
  );

  static const PluralTokenParser next = PluralTokenParser(
    normalForms: ['следующий', 'будущий'],
    forms: {
      'следующий': 1,
      'следующего': 1,
      'следующему': 1,
      'следующим': 1,
      'следующем': 1,
      'следующая': 1,
      'следующей': 1,
      'следующую': 1,
      'следующею': 1,
      'следующее': 1,
      'следующие': 2,
      'следующих': 2,
      'следующими': 2,
      'будущий': 1,
      'будущего': 1,
      'будущему': 1,
      'будущая': 1,
      'будущим': 1,
      'будущей': 1,
      'будущую': 1,
      'будущею': 1,
      'будущее': 1,
      'будущем': 1,
      'будущие': 2,
      'будущих': 2,
      'будущими': 2,
    },
    metaSymbol: 'x',
  );

  static const PluralTokenParser previous = PluralTokenParser(
    normalForms: ['прошлый', 'прошедший', 'предыдущий'],
    forms: {
      'прошлый': 1,
      'прошлого': 1,
      'прошлому': 1,
      'прошлым': 1,
      'прошлая': 1,
      'прошлой': 1,
      'прошлую': 1,
      'прошлою': 1,
      'прошлое': 1,
      'прошлом': 1,
      'прошлые': 2,
      'прошлых': 2,
      'прошлыми': 2,
      'прошедший': 1,
      'прошедшего': 1,
      'прошедшему': 1,
      'прошедшим': 1,
      'прошедшем': 1,
      'прошедшая': 1,
      'прошедшей': 1,
      'прошедшую': 1,
      'прошедшею': 1,
      'прошедшее': 1,
      'прошедшие': 2,
      'прошедших': 2,
      'прошедшими': 2,
      'предыдущий': 1,
      'предыдущего': 1,
      'предыдущему': 1,
      'предыдущим': 1,
      'предыдущем': 1,
      'предыдущая': 1,
      'предыдущей': 1,
      'предыдущую': 1,
      'предыдущею': 1,
      'предыдущее': 1,
      'предыдущие': 2,
      'предыдущих': 2,
      'предыдущими': 2,
    },
    metaSymbol: 's',
  );

  static const PluralTokenParser current = PluralTokenParser(
    normalForms: ['этот', 'текущий', 'нынешний'],
    forms: {
      'этот': 1,
      'этого': 1,
      'этому': 1,
      'этим': 1,
      'этом': 1,
      'эта': 1,
      'этой': 1,
      'эту': 1,
      'этою': 1,
      'это': 1,
      'эти': 2,
      'этих': 2,
      'этими': 2,
      'текущий': 1,
      'текущего': 1,
      'текущему': 1,
      'текущим': 1,
      'текущем': 1,
      'текущая': 1,
      'текущей': 1,
      'текущую': 1,
      'текущею': 1,
      'текущее': 1,
      'текущие': 2,
      'текущих': 2,
      'текущими': 2,
      'нынешний': 1,
      'нынешнего': 1,
      'нынешнему': 1,
      'нынешним': 1,
      'нынешнем': 1,
      'нынешняя': 1,
      'нынешней': 1,
      'нынешнюю': 1,
      'нынешнею': 1,
      'нынешнее': 1,
      'нынешние': 2,
      'нынешних': 2,
      'нынешними': 2,
    },
    metaSymbol: 'u',
  );

  static const PluralTokenParser currentNext = PluralTokenParser(
    normalForms: ['ближайший', 'грядущий'],
    forms: {
      'ближайший': 1,
      'грядущий': 1,
      'грядущего': 1,
      'грядущему': 1,
      'грядущим': 1,
      'грядущем': 1,
      'грядущая': 1,
      'грядущей': 1,
      'грядущую': 1,
      'грядущею': 1,
      'грядущее': 1,
      'грядущие': 2,
      'грядущих': 2,
      'грядущими': 2,
    },
    metaSymbol: 'y',
  );

  static const PluralTokenParser today = PluralTokenParser(
    normalForms: ['сегодня'],
    forms: {
      'сегодня': 1,
    },
    metaSymbol: '4',
  );

  static const PluralTokenParser tomorrow = PluralTokenParser(
    normalForms: ['завтра'],
    forms: {
      'завтра': 1,
    },
    metaSymbol: '5',
  );

  static const PluralTokenParser afterTomorrow = PluralTokenParser(
    normalForms: ['послезавтра'],
    forms: {
      'послезавтра': 1,
    },
    metaSymbol: '6',
  );

  static const PluralTokenParser yesterday = PluralTokenParser(
    normalForms: ['вчера'],
    forms: {
      'вчера': 1,
    },
    metaSymbol: '3',
  );

  static const PluralTokenParser beforeYesterday = PluralTokenParser(
    normalForms: ['позавчера'],
    forms: {
      'позавчера': 1,
    },
    metaSymbol: '2',
  );

  static const PluralTokenParser holiday = PluralTokenParser(
    normalForms: ['выходной'],
    forms: {
      'выходной': 1,
      'выходного': 1,
      'выходному': 1,
      'выходным': 1,
      'выходном': 1,
      'выходная': 1,
      'выходную': 1,
      'выходною': 1,
      'выходное': 1,
      'выходные': 2,
      'выходных': 2,
      'выходными': 2,
    },
    metaSymbol: 'W',
  );

  static const PluralTokenParser minute = PluralTokenParser(
    normalForms: ['минута', 'мин'],
    forms: {
      'минута': 1,
      'минуты': 1,
      'минуте': 1,
      'минуту': 1,
      'минутой': 1,
      'минутою': 1,
      'минут': 2,
      'минутам': 2,
      'минутами': 2,
      'минутах': 2,
      'мин': 1,
    },
    metaSymbol: 'e',
  );

  static const PluralTokenParser hour = PluralTokenParser(
    normalForms: ['час', 'ч'],
    forms: {
      'час': 1,
      'часа': 1,
      'часу': 1,
      'часом': 1,
      'часе': 1,
      'часы': 2,
      'часов': 2,
      'часам': 2,
      'часами': 2,
      'часах': 2,
    },
    metaSymbol: 'h',
  );

  static const PluralTokenParser day = PluralTokenParser(
    normalForms: ['день'],
    forms: {
      'день': 1,
      'дня': 1,
      'дню': 1,
      'дне': 1,
      'дни': 2,
      'дней': 2,
      'дням': 2,
      'днями': 2,
      'днях': 2,
      'днем': 0,
      'днём': 0,
    },
    metaSymbol: 'd',
  );

  static const PluralTokenParser week = PluralTokenParser(
    normalForms: ['неделя'],
    forms: {
      'неделя': 1,
      'недели': 1,
      'неделе': 1,
      'неделю': 1,
      'неделей': 1,
      'недель': 2,
      'неделям': 2,
      'неделями': 2,
      'неделях': 2,
    },
    metaSymbol: 'w',
  );

  static const PluralTokenParser month = PluralTokenParser(
    normalForms: ['месяц', 'мес'],
    forms: {
      'месяц': 1,
      'месяца': 1,
      'месяцу': 1,
      'месяцем': 1,
      'месяце': 1,
      'месяцы': 2,
      'месяцев': 2,
      'месяцам': 2,
      'месяцами': 2,
      'месяцах': 2,
      'мес': 1,
    },
    metaSymbol: 'm',
  );

  static const PluralTokenParser year = PluralTokenParser(
    normalForms: ['год'],
    forms: {
      'год': 1,
      'года': 1,
      'году': 1,
      'годом': 1,
      'годе': 1,
      'годов': 2,
      'годам': 2,
      'годами': 2,
      'годах': 2,
      'годы': 2,
      'лета': 2,
      'лет': 2,
      'летам': 2,
      'летами': 2,
      'летах': 2,
    },
    metaSymbol: 'Y',
  );

  static const PluralTokenParser noon = PluralTokenParser(
    normalForms: ['полдень'],
    forms: {
      'полдень': 1,
      'полдня': 1,
      'полдню': 1,
      'полднем': 1,
      'полдне': 1,
      'полдни': 2,
      'полдней': 2,
      'полдням': 2,
      'полднями': 2,
      'полднях': 2,
    },
    metaSymbol: 'n',
  );

  static const PluralTokenParser morning = PluralTokenParser(
    normalForms: ['утро'],
    forms: {
      'утро': 1,
      'утра': 1,
      'утру': 1,
      'утром': 1,
      'утре': 1,
      'утр': 2,
      'утрам': 2,
      'утрами': 2,
      'утрах': 2,
    },
    metaSymbol: 'r',
  );

  static const PluralTokenParser evening = PluralTokenParser(
    normalForms: ['вечер'],
    forms: {
      'вечер': 1,
      'вечера': 1,
      'вечеру': 1,
      'вечером': 1,
      'вечере': 1,
      'вечеров': 2,
      'вечерам': 2,
      'вечерами': 2,
      'вечерах': 2,
    },
    metaSymbol: 'v',
  );

  static const PluralTokenParser night = PluralTokenParser(
    normalForms: ['ночь'],
    forms: {
      'ночь': 1,
      'ночи': 1,
      'ночью': 1,
      'ночей': 2,
      'ночам': 2,
      'ночами': 2,
      'ночах': 2,
    },
    metaSymbol: 'g',
  );

  static const PluralTokenParser half = PluralTokenParser(
    normalForms: ['половина', 'пол'],
    forms: {
      'половина': 1,
      'половины': 1,
      'половине': 1,
      'половину': 1,
      'половиной': 1,
      'половиною': 1,
      'половин': 2,
      'половинам': 2,
      'половинами': 2,
      'половинах': 2,
      'пол': 1,
    },
    metaSymbol: 'H',
  );

  static const PluralTokenParser quarter = PluralTokenParser(
    normalForms: ['четверть'],
    forms: {
      'четверть': 1,
      'четверти': 1,
      'четвертью': 1,
      'четвертей': 2,
      'четвертям': 2,
      'четвертями': 2,
      'четвертях': 2,
    },
    metaSymbol: 'Q',
  );

  static const PluralTokenParser dayInMonth = PluralTokenParser(
    normalForms: ['число'],
    forms: {
      'число': 1,
      'числа': 1,
      'числу': 1,
      'числом': 1,
      'числе': 1,
      'чисел': 2,
      'числам': 2,
      'числами': 2,
      'числах': 2,
    },
    metaSymbol: '#',
  );

  static const OrderPluralTokenParser january = OrderPluralTokenParser(
    normalForms: ['январь', 'янв'],
    forms: {
      'январь': 1,
      'января': 1,
      'январю': 1,
      'январем': 1,
      'январём': 1,
      'январе': 1,
      'январи': 2,
      'январей': 2,
      'январям': 2,
      'январями': 2,
      'январях': 2,
      'янв': 1,
    },
    metaSymbol: 'M',
    order: DateTime.january,
  );

  static const OrderPluralTokenParser february = OrderPluralTokenParser(
    normalForms: ['февраль', 'фев'],
    forms: {
      'февраль': 1,
      'февраля': 1,
      'февралю': 1,
      'февралем': 1,
      'февралём': 1,
      'феврале': 1,
      'феврали': 2,
      'февралей': 2,
      'февралям': 2,
      'февралями': 2,
      'февралях': 2,
      'фев': 1,
    },
    metaSymbol: 'M',
    order: DateTime.february,
  );

  static const OrderPluralTokenParser march = OrderPluralTokenParser(
    normalForms: ['март', 'мар'],
    forms: {
      'март': 1,
      'марта': 1,
      'марту': 1,
      'мартом': 1,
      'марте': 1,
      'марты': 2,
      'мартов': 2,
      'мартам': 2,
      'мартами': 2,
      'мартах': 2,
      'мар': 1,
    },
    metaSymbol: 'M',
    order: DateTime.march,
  );

  static const OrderPluralTokenParser april = OrderPluralTokenParser(
    normalForms: ['апрель', 'апр'],
    forms: {
      'апрель': 1,
      'апреля': 1,
      'апрелю': 1,
      'апрелем': 1,
      'апреле': 1,
      'апрели': 2,
      'апрелей': 2,
      'апрелям': 2,
      'апрелями': 2,
      'апрелях': 2,
      'апр': 1,
    },
    metaSymbol: 'M',
    order: DateTime.april,
  );

  static const OrderPluralTokenParser may = OrderPluralTokenParser(
    normalForms: ['май', 'мая'],
    forms: {
      'май': 1,
      'мая': 1,
      'маю': 1,
      'маем': 1,
      'мае': 1,
      'маи': 2,
      'маев': 2,
      'маям': 2,
      'маями': 2,
      'маях': 2,
    },
    metaSymbol: 'M',
    order: DateTime.may,
  );

  static const OrderPluralTokenParser june = OrderPluralTokenParser(
    normalForms: ['июнь', 'июн'],
    forms: {
      'июнь': 1,
      'июня': 1,
      'июню': 1,
      'июнем': 1,
      'июне': 1,
      'июни': 2,
      'июней': 2,
      'июням': 2,
      'июнями': 2,
      'июнях': 2,
      'июн': 1,
    },
    metaSymbol: 'M',
    order: DateTime.june,
  );

  static const OrderPluralTokenParser july = OrderPluralTokenParser(
    normalForms: ['июль', 'июл'],
    forms: {
      'июль': 1,
      'июля': 1,
      'июлю': 1,
      'июлем': 1,
      'июле': 1,
      'июли': 2,
      'июлей': 2,
      'июлям': 2,
      'июлями': 2,
      'июлях': 2,
      'июл': 1,
    },
    metaSymbol: 'M',
    order: DateTime.july,
  );

  static const OrderPluralTokenParser august = OrderPluralTokenParser(
    normalForms: ['август', 'авг'],
    forms: {
      'август': 1,
      'августа': 1,
      'августу': 1,
      'августом': 1,
      'августе': 1,
      'августы': 2,
      'августов': 2,
      'августам': 2,
      'августами': 2,
      'августах': 2,
      'авг': 1,
    },
    metaSymbol: 'M',
    order: DateTime.august,
  );

  static const OrderPluralTokenParser september = OrderPluralTokenParser(
    normalForms: ['сентябрь', 'сен', 'сент'],
    forms: {
      'сентябрь': 1,
      'сентября': 1,
      'сентябрю': 1,
      'сентябрем': 1,
      'сентябрём': 1,
      'сентябре': 1,
      'сентябри': 2,
      'сентябрей': 2,
      'сентябрям': 2,
      'сентябрями': 2,
      'сентябрях': 2,
      'сен': 1,
      'сент': 1,
    },
    metaSymbol: 'M',
    order: DateTime.september,
  );

  static const OrderPluralTokenParser october = OrderPluralTokenParser(
    normalForms: ['октябрь', 'окт'],
    forms: {
      'октябрь': 1,
      'октября': 1,
      'октябрю': 1,
      'октябрем': 1,
      'октябрём': 1,
      'октябре': 1,
      'октябри': 2,
      'октябрей': 2,
      'октябрям': 2,
      'октябрями': 2,
      'октябрях': 2,
      'окт': 1,
    },
    metaSymbol: 'M',
    order: DateTime.october,
  );

  static const OrderPluralTokenParser november = OrderPluralTokenParser(
    normalForms: ['ноябрь', 'ноя', 'нояб'],
    forms: {
      'ноябрь': 1,
      'ноября': 1,
      'ноябрю': 1,
      'ноябрем': 1,
      'ноябрём': 1,
      'ноябре': 1,
      'ноябри': 2,
      'ноябрей': 2,
      'ноябрям': 2,
      'ноябрями': 2,
      'ноябрях': 2,
      'ноя': 1,
      'нояб': 1,
    },
    metaSymbol: 'M',
    order: DateTime.november,
  );

  static const OrderPluralTokenParser december = OrderPluralTokenParser(
    normalForms: ['декабрь', 'дек'],
    forms: {
      'декабрь': 1,
      'декабря': 1,
      'декабрю': 1,
      'декабрем': 1,
      'декабрём': 1,
      'декабре': 1,
      'декабри': 2,
      'декабрей': 2,
      'декабрям': 2,
      'декабрями': 2,
      'декабрях': 2,
      'дек': 1,
    },
    metaSymbol: 'M',
    order: DateTime.december,
  );

  static const OrderPluralTokenParser monday = OrderPluralTokenParser(
    normalForms: ['понедельник', 'пн'],
    forms: {
      'понедельник': 1,
      'понедельника': 1,
      'понедельнику': 1,
      'понедельником': 1,
      'понедельнике': 1,
      'понедельники': 2,
      'понедельников': 2,
      'понедельникам': 2,
      'понедельниками': 2,
      'понедельниках': 2,
      'пн': 1,
    },
    metaSymbol: 'D',
    order: DateTime.monday,
  );

  static const OrderPluralTokenParser tuesday = OrderPluralTokenParser(
    normalForms: ['вторник', 'вт'],
    forms: {
      'вторник': 1,
      'вторника': 1,
      'вторнику': 1,
      'вторником': 1,
      'вторнике': 1,
      'вторники': 2,
      'вторников': 2,
      'вторникам': 2,
      'вторниками': 2,
      'вторниках': 2,
      'вт': 1,
    },
    metaSymbol: 'D',
    order: DateTime.tuesday,
  );

  static const OrderPluralTokenParser wednesday = OrderPluralTokenParser(
    normalForms: ['среда', 'ср'],
    forms: {
      'среда': 1,
      'среды': 1,
      'среде': 1,
      'среду': 1,
      'средой': 1,
      'средою': 1,
      'сред': 2,
      'средам': 2,
      'средами': 2,
      'средах': 2,
      'ср': 1,
    },
    metaSymbol: 'D',
    order: DateTime.wednesday,
  );

  static const OrderPluralTokenParser thursday = OrderPluralTokenParser(
    normalForms: ['четверг', 'чт'],
    forms: {
      'четверг': 1,
      'четверга': 1,
      'четвергу': 1,
      'четвергом': 1,
      'четверге': 1,
      'четверги': 2,
      'четвергов': 2,
      'четвергам': 2,
      'четвергами': 2,
      'четвергах': 2,
      'чт': 1,
    },
    metaSymbol: 'D',
    order: DateTime.thursday,
  );

  static const OrderPluralTokenParser friday = OrderPluralTokenParser(
    normalForms: ['пятница', 'пт'],
    forms: {
      'пятница': 1,
      'пятницы': 1,
      'пятнице': 1,
      'пятницу': 1,
      'пятницей': 1,
      'пятницею': 1,
      'пятниц': 2,
      'пятницам': 2,
      'пятницами': 2,
      'пятницах': 2,
      'пт': 1,
    },
    metaSymbol: 'D',
    order: DateTime.friday,
  );

  static const OrderPluralTokenParser saturday = OrderPluralTokenParser(
    normalForms: ['суббота', 'сб'],
    forms: {
      'суббота': 1,
      'субботы': 1,
      'субботе': 1,
      'субботу': 1,
      'субботой': 1,
      'субботою': 1,
      'суббот': 2,
      'субботам': 2,
      'субботами': 2,
      'субботах': 2,
      'сб': 1,
    },
    metaSymbol: 'D',
    order: DateTime.saturday,
  );

  static const OrderPluralTokenParser sunday = OrderPluralTokenParser(
    normalForms: ['воскресенье', 'вс'],
    forms: {
      'воскресенье': 1,
      'воскресенья': 1,
      'воскресенью': 1,
      'воскресеньем': 1,
      'воскресеньи': 1,
      'воскресений': 2,
      'воскресеньям': 2,
      'воскресеньями': 2,
      'воскресеньях': 2,
      'вс': 1,
    },
    metaSymbol: 'D',
    order: DateTime.sunday,
  );

  static const PluralTokenParser daytimeDay = PluralTokenParser(
    normalForms: ['днём', 'днем'],
    forms: {
      'день': 1,
      'дня': 1,
      'дню': 1,
      'дне': 1,
      'дни': 2,
      'дней': 2,
      'дням': 2,
      'днями': 2,
      'днях': 2,
      'днем': 0,
      'днём': 0,
    },
    metaSymbol: 'a',
  );

  static const PluralTokenParser timeFrom = PluralTokenParser(
    normalForms: ['в', 'с'],
    forms: {
      'в': 0,
      'во': 0,
      'с': 0,
      'со': 0,
    },
    metaSymbol: 'f',
  );

  static const PluralTokenParser timeTo = PluralTokenParser(
    normalForms: ['до', 'по'],
    forms: {
      'до': 0,
      'по': 0,
    },
    metaSymbol: 't',
  );

  static const PluralTokenParser timeOn = PluralTokenParser(
    normalForms: ['на'],
    forms: {
      'на': 0,
    },
    metaSymbol: 'o',
  );

  static TokenParser yearNumbers = IntegerTokenParser(
    validator: (int integer) {
      return integer >= 1900 && integer <= 9999;
    },
    metaSymbol: '1',
  );

  static TokenParser numbers = IntegerTokenParser(
    validator: (int integer) {
      return integer >= 0 && integer < 1900;
    },
    metaSymbol: '0',
  );

  static TokenParser and = PluralTokenParser(
    normalForms: ['и'],
    forms: {
      'и': 0,
    },
    metaSymbol: 'N',
  );

  static const WordNumberTokenParser wZero = WordNumberTokenParser(
    forms: {'ноль'},
    value: 0,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wOne = WordNumberTokenParser(
    forms: {
      'один',
      'одна',
      'первый',
      'первая',
      'первое',
      'первые',
      'первого',
      'первой',
      'первых',
      'первому',
      'первым',
      'первую',
      'первою',
      'первыми',
      'первом',
    },
    value: 1,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wTwo = WordNumberTokenParser(
    forms: {
      'два',
      'две',
      'второй',
      'вторая',
      'второе',
      'вторые',
      'второго',
      'вторых',
      'второму',
      'вторым',
      'вторую',
      'второю',
      'вторыми',
      'втором',
    },
    value: 2,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wThree = WordNumberTokenParser(
    forms: {
      'три',
      'третий',
      'третьи',
      'третьего',
      'третьих',
      'третьему',
      'третьим',
      'третьими',
      'третьем',
      'третья',
      'третье',
      'третьей',
      'третью',
      'третьею',
    },
    value: 3,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFour = WordNumberTokenParser(
    forms: {
      'четвертое',
      'четвертого',
      'четыре',
      'четырёх',
      'четырём',
      'четырьмя',
      'четвертом',
      'четвёртом',
    },
    value: 4,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFive = WordNumberTokenParser(
    forms: {
      'пятое',
      'пятого',
      'пять',
      'пяти',
      'пятью',
    },
    value: 5,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSix = WordNumberTokenParser(
    forms: {
      'шестое',
      'шестого',
      'шесть',
      'шести',
      'шестью',
    },
    value: 6,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSeven = WordNumberTokenParser(
    forms: {
      'седьмого',
      'седьмое',
      'семь',
      'семи',
      'семью',
    },
    value: 7,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wEight = WordNumberTokenParser(
    forms: {
      'восьмое',
      'восьмого',
      'восемь',
      'восьми',
      'восемью',
      'восьмью',
    },
    value: 8,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wNine = WordNumberTokenParser(
    forms: {
      'девятое',
      'девятого',
      'девять',
      'девяти',
      'девятью',
    },
    value: 9,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wTen = WordNumberTokenParser(
    forms: {
      'десятого',
      'десятое',
      'десять',
      'десяти',
      'десятью',
    },
    value: 10,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wEleven = WordNumberTokenParser(
    forms: {
      'одиннадцатое',
      'одиннадцатого',
      'одиннадцать',
      'одиннадцати',
      'одиннадцатью',
    },
    value: 11,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wTwelve = WordNumberTokenParser(
    forms: {
      'двенадцатое',
      'двенадцатого',
      'двенадцать',
      'двенадцати',
      'двенадцатью',
    },
    value: 12,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wThirteen = WordNumberTokenParser(
    forms: {
      'тринадцатое',
      'тринадцатого',
      'тринадцать',
      'тринадцати',
      'тринадцатью',
    },
    value: 13,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFourteen = WordNumberTokenParser(
    forms: {
      'четырнадцатое',
      'четырнадцатого',
      'четырнадцать',
      'четырнадцати',
      'четырнадцатью',
    },
    value: 14,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFifteen = WordNumberTokenParser(
    forms: {
      'пятнадцатое',
      'пятнадцатого',
      'пятнадцать',
      'пятнадцати',
      'пятнадцатью',
    },
    value: 15,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSixteen = WordNumberTokenParser(
    forms: {
      'шестнадцатое',
      'шестнадцатого',
      'шестнадцать',
      'шестнадцати',
      'шестнадцатью',
    },
    value: 16,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSeventeen = WordNumberTokenParser(
    forms: {
      'семнадцатого',
      'семнадцатое',
      'семнадцать',
      'семнадцати',
      'семнадцатью',
    },
    value: 17,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wEighteen = WordNumberTokenParser(
    forms: {
      'восемнадцатого',
      'восемнадцатое',
      'восемнадцать',
      'восемнадцати',
      'восемнадцатью',
    },
    value: 18,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wNineteen = WordNumberTokenParser(
    forms: {
      'девятнадцатого',
      'девятнадцатое',
      'девятнадцать',
      'девятнадцати',
      'девятнадцатью',
    },
    value: 19,
    level: 1,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wTwenty = WordNumberTokenParser(
    forms: {
      'двадцатого',
      'двадцатое',
      'двадцать',
      'двадцати',
      'двадцатью',
    },
    value: 20,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wThirty = WordNumberTokenParser(
    forms: {
      'тридцатого',
      'тридцатое',
      'тридцать',
      'тридцати',
      'тридцатью',
    },
    value: 30,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFourty = WordNumberTokenParser(
    forms: {
      'сорокового',
      'сороковое',
      'сорок',
      'сорока',
    },
    value: 40,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFifty = WordNumberTokenParser(
    forms: {
      'пятьдесятого',
      'пятьдесятое',
      'пятьдесят',
      'пятидесяти',
      'пятидесятью',
    },
    value: 50,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSixty = WordNumberTokenParser(
    forms: {
      'шестьдесятого',
      'шестьдесятое',
      'шестьдесят',
      'шестидесяти',
      'шестидесятью',
    },
    value: 60,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSeventy = WordNumberTokenParser(
    forms: {
      'семьдесятого',
      'семьдесятое',
      'семьдесят',
      'семьдесяти',
      'семьдесятью',
    },
    value: 70,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wEighty = WordNumberTokenParser(
    forms: {
      'восемьдесятого',
      'восемьдесятое',
      'восемьдесят',
      'восемидесяти',
      'восемидесятью',
    },
    value: 80,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wNinety = WordNumberTokenParser(
    forms: {
      'девяностого',
      'девяностое',
      'девяносто',
    },
    value: 90,
    level: 2,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wOneHundred = WordNumberTokenParser(
    forms: {
      'сто',
      'ста',
      'сотня',
    },
    value: 100,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wTwoHundred = WordNumberTokenParser(
    forms: {
      'двести',
      'двухсот',
      'двумстам',
      'двумястами',
      'двухстах',
    },
    value: 200,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wThreeHundred = WordNumberTokenParser(
    forms: {
      'триста',
      'трехсот',
      'трёхсот',
      'трехстам',
      'трёхстам',
      'тремястами',
      'тремстах',
      'трёмстах',
    },
    value: 300,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFourHundred = WordNumberTokenParser(
    forms: {
      'четыреста',
      'четырехсот',
      'четырехстам',
      'четырмястами',
      'четырмястах',
    },
    value: 400,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wFiveHundred = WordNumberTokenParser(
    forms: {
      'пятьсот',
      'пятиста',
      'пятисот',
      'пятистам',
      'пятистами',
      'пятистах',
    },
    value: 500,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSixHundred = WordNumberTokenParser(
    forms: {
      'шестьсот',
      'шестиста',
      'шестисот',
      'шестистам',
      'шестистами',
      'шестистах',
    },
    value: 600,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wSevenHundred = WordNumberTokenParser(
    forms: {
      'семьсот',
      'семиста',
      'семисот',
      'семистам',
      'семистами',
      'семистах',
    },
    value: 700,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wEightHundred = WordNumberTokenParser(
    forms: {
      'восемьсот',
      'восьмиста',
      'восьмисот',
      'восьмистам',
      'восьмистами',
      'восьмистах',
    },
    value: 800,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wNineHundred = WordNumberTokenParser(
    forms: {
      'девятьсот',
      'девятиста',
      'девятисот',
      'девятистам',
      'девятистами',
      'девятистах',
    },
    value: 900,
    level: 3,
    isMultiplier: false,
    metaSymbol: 'x',
  );

  static const WordNumberTokenParser wThousand = WordNumberTokenParser(
    forms: {
      'тысяча',
      'тысячи',
      'тысяч',
      'тысяче',
      'тысячам',
      'тысячу',
      'тысячей',
      'тысячею',
      'тысячами',
      'тысячах',
    },
    value: 1000,
    level: 4,
    isMultiplier: true,
    metaSymbol: 'x',
  );

  static const List<WordNumberTokenParser> numbersInWords = [
    wZero,
    wOne,
    wTwo,
    wThree,
    wFour,
    wFive,
    wSix,
    wSeven,
    wEight,
    wNine,
    wTen,
    wEleven,
    wTwelve,
    wThirteen,
    wFourteen,
    wFifteen,
    wSixteen,
    wSeventeen,
    wEighteen,
    wNineteen,
    wTwenty,
    wThirty,
    wFourty,
    wFifty,
    wSixty,
    wSeventy,
    wEighty,
    wNinety,
    wOneHundred,
    wTwoHundred,
    wThreeHundred,
    wFourHundred,
    wFiveHundred,
    wSixHundred,
    wSevenHundred,
    wEightHundred,
    wNineHundred,
    wThousand,
  ];

  /// List of all month parsers in russian.
  static const List<OrderPluralTokenParser> months = [
    january,
    february,
    march,
    april,
    may,
    june,
    july,
    august,
    september,
    october,
    november,
    december,
  ];

  /// List of all days of week parsers in russian.
  static const List<OrderPluralTokenParser> daysOfWeek = [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  /// List of all default russian parsers.
  static final List<TokenParser> all = [
    after,
    afterPostfix,
    previousPostfix,
    next,
    previous,
    current,
    currentNext,
    today,
    tomorrow,
    afterTomorrow,
    yesterday,
    beforeYesterday,
    holiday,
    minute,
    hour,
    day,
    week,
    month,
    year,
    noon,
    morning,
    evening,
    night,
    half,
    quarter,
    dayInMonth,
    january,
    february,
    march,
    april,
    may,
    june,
    july,
    august,
    september,
    october,
    november,
    december,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
    daytimeDay,
    timeFrom,
    timeTo,
    timeOn,
    yearNumbers,
    numbers,
    and,
    ...numbersInWords,
  ];
}
