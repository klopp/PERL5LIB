# Разные логеры

* [Базовый класс](#базовый-класс)
* [Асинхронность](#асинхронность)

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

### Базовый формат

Строка лога формируется по шаблону `"ДАТА ВРЕМЯ PID УРОВЕНЬ СООБЩЕНИЕ"`:

```
2023-06-28 22:09:08 391634 INFO что-то хочется сказать
```

### Общие аргументы конструктора

```
my $logger = Things::Log::XYZ->new( comments => BOOL, microsec => BOOL, level => LOG_LEVEL );
```

Эти аргументы обрабатываются всеми классами-потомками одинаково.

#### level => LOG_LEVEL

По умолчанию `$LOG_INFO`.

#### comments => BOOL

Строки, начинающиеся с символов `'`, `#` и `;` считаются комментариями и выводятся в лог только если `comments => TRUE`:

```
$log->info( '%s', '; optional string' );
# comments => FALSE, в лог не пойдёт вообще ничего
# comments => TRUE, в лог пойдёт строка 'optional string'
```

По умолчанию `FALSE`. Может меняться динамически:

```
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
 
Поле `message` в этой структуре будет использоваться всегда.

## Асинхронность

Этот метод переводит логирование в неблокирующий режим (вывод в лог ставится в очередь, которая разгребается отдельным потоком):

### sub nb()

Может быть вызван один раз, все последующие вызовы игнорируются. Отменить неблокирующий режим нельзя.

### [Things::Log::File](Things/Log/File.pm)

Лог в файл. Имя файла в конструкторе:

```perl
    my $logger = Things::Log::File->new( file => '/var/log/my.log' );
    Carp::confess $logger->{error} if $logger->{error};
    $logger->info( 'Hello from %s!', $PROGRAM_NAME );  
```

### [Things::Log::Std](Things/Log/Std.pm)

Лог в `STDOUT`. При этом перехватываются:

#### вывод в STDERR 

Преобразуется в `$logger->notice()`

#### warn() 

Преобразуется в `$logger->warn()`

#### die() 

Преобразуется в `$logger->emergency()` с последующим `die`.

### [Things::Log::Url](Things/Log/Url.pm)

Лог в URL.

### [Things::Log::Db](Things/Log/Db.pm)

Лог в любой объект, умеющий [DBI::do()](https://metacpan.org/pod/DBI#do).
