# PERL5LIB

Всякие перловости, которые использую.

## [AnyEvent::Sleep](AnyEvent/Sleep.pm)

Стырено [отсюда](https://github.com/iarna/AnyEvent-Sleep). Спальник на N секунд, или до конкретного времени, без остановки обработки событий.

## [data/](data/)

Хранилице внутренних баз.

## [Things](Things.pm)

Набор всяких разных функций и констант.

## [Things::*](Things/)

Небольшие полезные модули.

### [Things::ConfigPP](Things/ConfigPP.pm)

Использование в качестве конфига файла с перловыми данными.

  * Ключи приводятся к нижнему регистру.
  * Скалярные значения декодируются в перловый `UTF8`.
  * Значения с одинаковыми ключами будут преобразованы в массивы, если ключи указаны в конструкторе. Иначе будет использоваться последнее значение.
  * `"*"` или `"all"` в конструкторе приведёт к преобразованию в массивы всех ключей, `"-"` - ни один ключ не сконвертируется в массив.

### [Things::ConfigStd](Things/ConfigStd.pm)

Обёртка над [Config::Std](https://metacpan.org/pod/Config::Std).
Всё то же самое, плюс данные вне секций сохраняются в секции `"_"`.

### [Things::HashOrdered](Things/HashOrdered.pm)

Обёртка над [Hash::Ordered](https://metacpan.org/pod/Hash::Ordered), позволяющая использовать стандартный синтаксис `$hash->{}`, `$hash{}` и `each(%hash)`.

### [Things::Sqlite](Things/Sqlite.pm), [Things::Mysql](Things/Mysql.pm),  [Things::Pg](Things/Pg.pm)

DBI-шные обёртки для разных БД, реализующий единый интерфейс. Поддерживают все методы DBI, плюс:

#### sub upsert( )

Вставка с заменой.

#### sub select_field()

Выборка одного поля, возвращает его значение.

#### sub select_fields()

Выборка одного поля из нескольких записей, возвращает массив значений.

#### sub cset(), sub cget()

Чтение и установка скалярных значений в таблице `config`.

#### sub cjset(), sub cjget()

Чтение и установка JSON-значений в таблице `config`.

## [Mutex::*](Mutex/)

Обёртки для различных реализаций мьютексов. Все приведены к одному интерфейсу:

```perl
    my $mutex = Mutex::MUTEX_CLASS->new( ... );
    my $error = $mutex->lock;
    $error and confess $error;
    $mutex->unlock;
```

## [Atomic::*](Atomic/)

Реализация атомарной (плюс многопоточной) обработки данных. Подробней в тамошнем [README](Atomic/README.md).
