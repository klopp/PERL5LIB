Обёртки для различных реализаций мьютексов. Все приведены к одному интерфейсу:

```perl
    my $mutex = Mutex::MUTEX_CLASS->new( ... );
    my $error = $mutex->lock;
    $error and confess $error;
    $mutex->unlock;
```