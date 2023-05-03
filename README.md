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

#### sub random_line( filename [, noempty = BOOL] )

Возвращает случайную строку файла (не пустую при `$noempty`)

### [Things::Out](Things/Out.pm)

Небольшик обёртки над функциями стандартного вывода (`puts()` => гибрид `say()`+`printf()`, и т.д.).

### [Things::Trim](Things/Trim.pm)

#### sub trim( data [, mod = BOOL] )

Принимает ссылку на хэш, ссылку на массив или скаляр. Возвращает копию исходных данных, у которой удаляет конечные и начальные `\s` значений. Если `mod`, то все поля исходных данных (кроме `readonly`) также будут модифицированы.

### [Things::Xget](Things/Xget.pm)

#### sub xget( data, xpath )

Возвращает значение из структуры по пути (например, `"/a/b/c/d/[2]"`). Предотвращает `autovification` при обращении к несуществующим значениям.

### [Things::Config::Find](Things/Config/Find.pm)

#### Things::Config::Find->find( )

Ищет конфиг программ в (`$name` и `$DIR` берутся из `$PROGRAM_NAME`, у имени отсекается "расширение"):

  * `$XDG_HOME_DIR/.$name + [.conf, .rc]`
  * `$HOME/.$name + [.conf, .rc]`
  * `$HOME/.config/$name + [.conf, .rc]`
  * `$DIR/$name[.conf, .rc]`
  * `/etc/$name[.conf, .rc]`
  * `/etc/default/$name`
  
Возвращает имя первого найденного файла или `undef`.

#### Things::Config::Find->tested_files( )

Возвращает список просмотренных файлов на этапе `find()`.

### [Things::Config::Perl](Things/Config/Perl.pm)

Использование в качестве конфига файла с перловыми данными (только чтение).

```perl
    my $conf = Things::Config::Perl->new( file => '/home/user/my.conf', nocase = 0 );
    Carp::confess $conf->{error} if $conf->{error};
    my $value = $conf->get( '/some/key' ); 
```

Может искать конфиги по умолчанию ([Things::Config::Find->find()](https://metacpan.org/pod/Config::Find)), если имя файла одно из: `?`, `-`, `*`, `def`, `default`, `find`, `search`. 

  * Ключи приводятся к нижнему регистру, если не `nocase`.
  * Скалярные значения декодируются в перловый `UTF8`.
  * Все значения преобразуются в массивы.
  * `get()` в скалярном контексте возвращает последнее значение ключа, в списковом - все.

### [Things::Config::Std](Things/Config/Std.pm)

Всё почти тоже самое, конфиг стандартный, но с вложенными секциями:

```ini
    # comment line, may start with [;] [:] ['] ["]
    root_value "root value"
    multiline "multi\nline"
    [section]
    !key a
    ' keep spaces:
    !key " aa "
    [section/sub.section!]
    @key b
    ; escapes:
    @key "b\tb"
    [section/sub.section!/sub.sub+section?]
    %key c
    $key cc
```

  * Многострочных значений нет (но можно использовать `\n`).
  * Комментарии только по одной строке целиком.
  * Разделитель подсекций - `/`.
  * Ограничений на символы в именах ключей и секций нет. 

### [Things::HashOrdered](Things/HashOrdered.pm)

Обёртка над [Hash::Ordered](https://metacpan.org/pod/Hash::Ordered), позволяющая использовать стандартный синтаксис `$hash->{}`, `$hash{}` и `each(%hash)`.

### [Things::String](Things/String.pm)

Небольшое расширение для обычных строковых скаляров:

```perl
    use Things::String;
    # string my $string, 'abc';
    # или
    # string my $string => 'abc';
    # say $string->ucfirst;
    # ...
```

Плюс перегружены некоторые операторы, включая `++` (стандартный строковый инкремент), `--` (обратная процедура, чего нет в Perl), `+`, `+=`, `&`, `&=` (конкатенация), `*`  (аналогично `x`), etc.

### [Things::UUID](Things/UUID.pm)

Сахар для [UUID](https://metacpan.org/pod/UUID). Экспортирует синглтон `$uuid`:


```perl
    # по умолчанию экспортируется $uuid:
    use Things::UUID;
    # но можно указать любое другое имя:
    # use Things::UUID qw/$UU_ID/;
    puts( $uuid );   # stringify $uuid
    $uuid++;         # generate next UUID
    puts( $uuid );
    puts( ++$uuid ); # and next
    # ...
```

**NB!** Зачем нужны пляски с `tie` в `Things::String` и `Things::UUID`. Дело в том, что такие присвоения:

```perl
    string my $string => 'xyz';
    $string = 'abc';
```
 убивают объект и превращают его в банальный скаляр (или что там будет присвоено). Перегрузка глобального оператора `=` в Perl *невозможна by design*. А вот базовый класс `Things::TieData` отслеживает и корректно обрабатывает такие ситуации.

### [Things::Xargs](Things/Xargs.pm)

Проверка аргументов функций и методов.

#### sub xargs(...)

Проверяет что ей передана ссылка на хэш или хэш. Нет - бросает исключение. Да - возвращает ссылку на хэш.

#### sub selfopt(HASH or BLESSED, @ )

Выполняет все проверки из `xargs()` и выставляет `$self->{error}` в случае ошибок:

```perl
    sub new {
        my $class = shift;
        my $self = bless {}, $class;
        ( $self, my $opt ) = selfopt( $self, @_ );
        $self->{error} and return $self;
    }  
```

### [Things::Instance::LockSock](Things/Instance/LockSock.pm)

#### sub lock_instance( FILE )

Проверка запущеного процесса и его блокировка. Возвращает либо хэш с описанием ошибки, либо ссылку на объект [Lock::Socket](https://metacpan.org/pod/Lock::Socket) (для снятия блокировки его нужно освободить):

```perl
    # our @EXPORT      = qw/lock_instance/;
    # our @EXPORT_OK   = qw/ lock_instance 
    #                        lock_or_croak lock_or_confess 
    #                        lock_and_cluck lock_and_carp /;
    # our %EXPORT_TAGS = (
    #    'all'  => \@EXPORT_OK,
    #    'die'  => qw/lock_or_croak lock_or_confess/,
    #    'warn' => qw/lock_and_cluck lock_and_carp/,
    # );
    #
    use Things::Instance::LockSock qw/lock_or_confess/;
    lock_or_confess($LOCKFILE);
    #
    # OR [, OR...]
    #
    use Things::Instance::LockSock;
    my $lock = lock_instance($LOCKFILE);
    $lock->{errno} and Carp::croak $lock->{msg};
    #
    # OR
    #
    use Things::Instance::LockSock;
    my $lock = lock_instance($LOCKFILE);
    if ( $lock->{errno} ) {
        if ( $lock->{reason} eq 'open' ) {
            Carp::confess sprintf 'Open file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'lock' ) {
            Carp::confess sprintf 'Lock process on port %u (%s)!', $lock->{port}, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'write' ) {
            Carp::confess sprintf 'Write file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        else {
            Carp::confess sprintf 'Unknown error reason (%s)!', $lock->{errno};
        }
        exit 1;
    }
    #
    # do something
    #
    undef $lock;
```

### [Things::Instance::LockFile](Things/Instance/LockFile.pm)

#### sub lock_instance( FILE [, close = BOOL] )

То же самое, но сместо сокета используется отслеживание процесса по `PID`. Функции те же, в случае успеха возвращают либо пустой хэш (`{}`), либо, если задан второй аргумент:

```perl
    { fh => $lock_file_handle }
```
Это на тот случай, если процесс будет форкаться. В таком  случае необходимо записать в файл `PID` рабочего потомка и закрыть его, схематично:

```perl
    my $rc = lock_instance( $lockfile, 1 );
    Carp::confess $rc->{msg} if $rc->{errno};
    exit if fork();
    exit if fork();
    # лучше не забывать про \n:
    syswrite $rc->{fh}, "$PID\n";
    close $rc->{fh};
```

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
