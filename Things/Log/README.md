# Разные логеры

* [Базовый класс](#базовый-класс)
    * [Формат лога](#формат-лога)
    * [Общие аргументы конструктора](#общие-аргументы-конструктора)
* [Асинхронность](#асинхронность)
* [Things::Log::File](#thingslogfile)
* [Things::Log::Std](#thingslogstd)
* [Things::Log::Syslog](#thingslogsyslog)
* [Things::Log::Xml](#thingslogxml)
* [Things::Log::Json](#thingslogjson)
* [Things::Log::Csv](#thingslogcsv)
* [Things::Log::Db](#thingslogdb)
* [Things::Log::Http](#thingsloghttp)
* [Things::Log::Redis](#thingslogredis)
* [Things::Log::Mongo](#thingslogmongo)

## Базовый класс

[Things::Log::Base](Base.pm)

Экспортирует константы от `$LOG_EMERGENCY` до `$LOG_TRACE`. Для всех уровней экспортирует методы, которые принимают аргументы в формате `printf()`:

* emergency(), emerg()
* alert()
* critical(), crit()
* error(), err()
* warning(), warn()
* notice(), not()
* info(), inf()
* debug(), dbg()
* trace(), trc()

### Формат лога

Строка лога формируется по шаблону `"ДАТА ВРЕМЯ PID УРОВЕНЬ СООБЩЕНИЕ"`:

```
    2023-06-28 22:09:08 391634 INFO что-то хочется сказать
```

### Общие аргументы конструктора

```perl
    my $logger = Things::Log::XYZ->new( comments => BOOL, microsec => BOOL, level => LOG_LEVEL );
```

Эти аргументы обрабатываются всеми классами-потомками одинаково.

#### level => LOG_LEVEL

По умолчанию `$LOG_INFO`.

#### comments => BOOL

Строки, начинающиеся с символов `'`, `#` и `;` считаются комментариями и выводятся в лог только если `comments => TRUE`:

```perl
    $log->info( '%s', '; optional string' );
    # comments => FALSE, в лог не пойдёт вообще ничего
    # comments => TRUE, в лог пойдёт строка 'optional string'
```

По умолчанию `FALSE`. Может меняться динамически:

```perl
    $log->comments(0);
    $log->info( '%s', '; optional string' );
    $log->comments(1);
    $log->error( '%s', '; maybe error' );
```

#### microsec => BOOL

По умолчанию `FALSE`. В случае `TRUE` к дате в строке лога будут добавлены микросекунды:

```
    2023-06-28 22:09:08.562396 391634 INFO очень полезная информация
```

#### fields => { STRING | ARRAY }

Массив или строка значений, разделитель - пробел, `,` или `;`. Регистр значения не имеет. Задаёт список полей внутренней структуры, которая используется для формирования записи лога в XML, БД, и т.д. (см. соответствующие классы ниже).  Возможные значения полей:

* `pid`
* `tstamp`
* `level`
* `host`
* `exe` - имя программы и командная строка, если есть
* `trace` - массив строк со стеком вызовов:

```
1 main::tst() at line 69 of "./c.pl"
2 main::sts() at line 59 of "./c.pl"
...
```
 
Поле `message` в этой структуре будет использоваться всегда. При указании `"all"` или `"*"` в структуру будут включены все поля. 

## Асинхронность

Этот метод переводит логирование в неблокирующий режим (вывод в лог ставится в очередь, которая разгребается отдельным потоком):

### sub nb()

Может быть вызван один раз, все последующие вызовы игнорируются. Отменить неблокирующий режим нельзя.

## [Things::Log::File](Things/Log/File.pm)

Лог в файл. Параметры `fields` игнорируются. Имя файла в конструкторе:

```perl
    my $logger = Things::Log::File->new( file => '/var/log/my.log' );
    Carp::confess $logger->{error} if $logger->{error};
    $logger->info( 'Hello from %s!', $PROGRAM_NAME );  
```

## [Things::Log::Std](Things/Log/Std.pm)

Лог в `STDOUT`. Параметры `fields` игнорируются. Перехватываются:

### вывод в STDERR 

Преобразуется в `$logger->notice()`

### warn() 

Преобразуется в `$logger->warn()`

### die() 

Преобразуется в `$logger->emergency()` с последующим `Carp::croak`.

## [Things::Log::Syslog](Things/Log/Syslog.pm)

Используется `syslog.` Параметры `fields` игнорируются. 

```perl
    use English qw/-no_match_vars/;
    use File::Basename qw/basename/;
    use Sys::Syslog qw(:macros);
    use Things::Log::Syslog;
    my $log = Things::Log::Syslog->new(
        level    => $LOG_INFO, 
        opt      => 'ndelay,nofatal',
        facility => LOG_LOCAL0|LOG_DAEMON,
        ident    => basename $PROGRAM_NAME,
    );
```

В конструкторе:

### sock => ...

Параметры сокета, подробней в описании [Sys::Syslog#setlogsock()](https://metacpan.org/pod/Sys::Syslog#FUNCTIONS). По умолчанию не используется.

### ident => STRING

Идентификатор (префикс) для сообщений. По умолчанию пустая строка.

### opt => STRING

Параметры: [Sys::Syslog#openlog()/Options](https://metacpan.org/pod/Sys::Syslog#FUNCTIONS). По умолчанию пустая строка.

### facility => VALUE

См. [Sys::Syslog#Facilities](https://metacpan.org/pod/Sys::Syslog#Facilities).

## [Things::Log::Xml](Things/Log/Xml.pm)

Пишет файл в формате XML. Конструктор наследуется из `Things::Log::File`. Дополнительные параметры:

### xml => { key => value ... }

Параметры [XML::Hash::XS](https://metacpan.org/pod/XML::Hash::XS#OPTIONS). Ключ `root` по умолчанию выставляется в `"log"`, ключ `canonical` всегда `TRUE`.

```xml
    <log><message>2023-07-09 18:26:45 491269 INFO сообщение</message></log>
```

Формат записи при задании полей в параметре `fields`:

```xml
    <log>
        <exe>./c.pl arg arg</exe>
        <host>localhost</host>
        <level>INFO</level>
        <message>сообщение</message
        <pid>12345678</pid>
        <trace>1 main::tst() at line 67 of "./c.pl"</trace>
        <trace>2 main::sts() at line 61 of "./c.pl"</trace>
        <tstamp>1688915709</tstamp>
    </log>
```

## [Things::Log::Json](Things/Log/Json.pm)

Пишет файл в формате JSON. Конструктор наследуется из `Things::Log::File`. Дополнительные параметры:

### json => { key => value ... }

Методы [JSON::XS](https://metacpan.org/pod/JSON::XS#OBJECT-ORIENTED-INTERFACE). Параметр `canonical` всегда `TRUE`.

```js
    {"message":"2023-07-09 18:33:56 492829 INFO сообщение"}
```

Формат записи при задании полей в параметре `fields`:

```js
    {
      "exe":"./c.pl",
      "host":"localhost",
      "level":"INFO",
      "message":"сообщение",
      "pid":493219,
      "trace":
      [
        "1 main::tst() at line 67 of \"./c.pl\"",
        "2 main::sts() at line 61 of \"./c.pl\""
      ],
      "tstamp":1688916904
    }
```

## [Things::Log::Csv](Things/Log/Csv.pm)

Пишет файл в формате CSV. Конструктор наследуется из `Things::Log::File`. Дополнительные параметры:

### csv => { key => value ... }

Параметры [Text::CSV](https://metacpan.org/pod/Text::CSV#new). Параметр `binary` всегда `TRUE`.

```
    "2023-07-09 18:42:27 494578 INFO сообщение"
```

Формат записи при задании полей в параметре `fields` (в одну строку, в алфавитном порядке: `"exe","host","level","message","pid","trace","tstamp"`, строки `trace` разделены `"\n"`):

```
    ./c.pl,
    localhost,
    INFO,
    "сообщение с пробелами",
    494868,
    "1 main::tst() at line 67 of ""./c.pl""
     2 main::sts() at line 61 of ""./c.pl""",
    1688917416
```

## [Things::Log::Db](Things/Log/Db.pm)

## [Things::Log::Http](Things/Log/Http.pm)

## [Things::Log::Redis](Things/Log/Redis.pm)

## [Things::Log::Mongo](Things/Log/Mongo.pm)


