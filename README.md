# Peque

Persistent global queue in form of OTP Application.

## Usage

See documentation:

``` shell
$ mix docs
$ open docs/index.html
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `peque` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:peque, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/peque](https://hexdocs.pm/peque).

## Idea

Тут по русски писать уже буду чтобы всем было проще.

Подход:

* Реализовать простую быструю очередь: `Peque.Queue.Fast`
* Реализовать дисковое хранилище для такой очереди: `Peque.Storage.DETS`
* Обернуть хранилище в `GenServer` и все операции записи делать через cast'ы
  * на каждые `Application.get_env(:peque, :ops_cast_limit)` операций делать call ping - так не дадим message box'у переполниться
* Реализовать очередь, которая будет записываться в хранилище: `Peque.Queue.Persistent`
* Спрятать эту очередь за гипервизором
  * используя `:trap_exits` сделать graceful shutdown

Есть много моментов где можно улучшить и соптимизировать - предмет для устного обсуждения. Тем не менее в текущем виде очередь работоспособна и неплохо ведет себя под искусственной нагрузкой.
