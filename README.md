# PERL5LIB

Всякие перловости, которые использую.

## [AnyEvent::Sleep](AnyEvent/Sleep.pm)

Стырено [отсюда](https://github.com/iarna/AnyEvent-Sleep). Спальник на N секунд, или до конкретного времени, без остановки обработки событий.

## [data/](data/)

Хранилице внутренних баз.

## [Things::*](Things/)

Всякие полезные модули.

### [Things::I2S](Things/I2S.pm)

#### sub i2s( )
#### sub interval_to_seconds( )

Разбирают строки вида:

```perl
"1d, 24m, 3h, 30s" => 1 day, 3 hours, 24 minutes, 30 seconds
```
или

```perl
"23:3:6:15" => 23 days, 3 hours, 6 minutes, 15 seconds
"3:6:15"    => 3 hours, 6 minutes, 15 seconds
```

Возвращают количество секунд.

### [Things::IP](Things/IP.pm)

#### sub long2ip( )
#### sub ip2long( )

### [Things::RandomLine](Things/RandomLine.pm)

#### sub random_line( filename [, noempty] )

Возвращает случайную строку файла (не пустую при `$noempty`)

### [Things::Out](Things/Out.pm)

Небольшик обёртки над функциями стандартного вывода (`puts()` => гибрид `say()`+`printf()`, и т.д.).

### [Things::Trim](Things/Trim.pm)

#### sub trim( data [, mod = BOOLEAN] )

Принимает хэш, массив или скаляр. Возвращает копию исходных данных, у которой удаляет конечные и начальные `\s` значений. Если `mod`, то все поля исходных данных (кроме `readonly`) также будут модифицированы.

### [Things::Xget](Things/Xget.pm)

#### sub xget( data, xpath )

Возвращает значение из структуры по пути (например, `"/a/b/c/d/[2]"`). Предотвращает `autovification` при обращении к несуществующим значениям.

### [Things::ConfigPP](Things/ConfigPP.pm)

Использование в качестве конфига файла с перловыми данными (только чтение).

  * Ключи приводятся к нижнему регистру.
  * Скалярные значения декодируются в перловый `UTF8`.
  * Значения с одинаковыми ключами будут преобразованы в массивы, если ключи указаны в конструкторе. Иначе будет использоваться последнее значение.
  * `"*"` или `"all"` в конструкторе приведёт к преобразованию в массивы всех ключей, `"-"` - ни один ключ не сконвертируется в массив.
  * Скалярные значения декодируются в перловый `UTF8`.
  * Корневой ключ - `"_"`. Но в методе `get()` его указывать не нужно.

### [Things::ConfigStd](Things/ConfigStd.pm)

Обёртка над [Config::Std](https://metacpan.org/pod/Config::Std).

Всё тоже самое, и
 
  * Данные вне секций сохраняются в секции `"_"`.

### [Things::HashOrdered](Things/HashOrdered.pm)

Обёртка над [Hash::Ordered](https://metacpan.org/pod/Hash::Ordered), позволяющая использовать стандартный синтаксис `$hash->{}`, `$hash{}` и `each(%hash)`.

### [Things::String](Things/String.pm)

Небольшое расширение для обычных строковых скаляров:

```perl
    use Things::String;
    # string my $string, 'abc';
    # или
    # string my $string => 'abc';
    # ...
```

Плюс перегружены некоторые операторы, включая `++` и `--`.


### [Things::UUID](Things/UUID.pm)

Сахар для [UUID](https://metacpan.org/pod/UUID):


```perl
    use Things::UUID;
    uuid my $uuid;
    puts( $uuid );   # stringify $uuid
    $uuid++;         # generate next UUID
    puts( $uuid );
    puts( ++$uuid ); # and next
    # ...
```

**NB!** Зачем нужны пляски с `tie` здесь и в `Things::String`. Дело в том, что присвоения типа таких убивают объект и превращают его в банальный скаляр (или что там будет присвоено):

```perl
    string my $string => 'xyz';
    $string = 'abc';
```

Перегрузка глобального оператора `=` в Perl *невозможна by design*. А вот базовый класс `Things::TieData` отслеживает и корректно обрабатывает такие ситуации.

### [Things::Args](Things/Args.pm)

Проверка аргументов функций и методов.

#### sub hargs(...)

Проверяет что ей передана ссылка на хэш или хэш. Нет - бросает исключение. Да - возвращает ссылку на хэш.

#### sub xargs(...)

То же самое, но в случае одного аргумента пропускает произвольное значение.

### [Things::Sqlite](Things/Sqlite.pm), [Things::Mysql](Things/Mysql.pm),  [Things::Pg](Things/Pg.pm)

DBI-шные обёртки для разных БД, реализующий единый интерфейс. Поддерживают все методы DBI, плюс:

#### sub upsert()

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
