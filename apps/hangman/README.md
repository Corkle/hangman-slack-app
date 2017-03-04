# Hangman

An OTP Application to play games of Hangman

## Setup 
*Note*: Make sure you have [Elixir 1.4](http://elixir-lang.org/install.html) or greater installed

```sh
  git clone https://github.com/Corkle/hangman_otp.git
  cd hangman_otp
  iex -S mix
```

## Usage

```elixir
iex> Hangman.connect("MY_ID")
{:ok,
 %{failures_remaining: 10, guessed: [], id: "MY_ID",
   puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "_",
    "_", "_", "_", "_", "!"], status: :new_game}}
iex> Hangman.guess("MY_ID", "e")
{:ok,
 {:correct,
  %{failures_remaining: 10, guessed: ["e"], id: "MY_ID",
    puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "e",
     "_", "_", "e", "_", "!"], status: :in_progress}}}
iex> Hangman.guess("MY_ID", "x")
{:ok,
 {:incorrect,
  %{failures_remaining: 9, guessed: ["x", "e"], id: "MY_ID",
    puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "e",
     "_", "_", "e", "_", "!"], status: :in_progress}}}
```

* `connect(id)` - Creates a new game session registered under `id`. Returns the current game session state if `id` is already a registered process (the same result as calling `get(id)`).
* `guess(id, letter)` - Checks if `letter` is found in the secret word/phrase for the game sesssion associated with `id`. `letter` should be a single character string (e.g. "p"). The result of the guess is returned with the updated game session state. When `:game_over` is returned, the registered game session process is terminated.
* `get(id)` - Returns the current state of the game session registered with `id`.
