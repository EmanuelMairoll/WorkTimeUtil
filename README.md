# WorkTimeUtil

WorkTimeUtil is a small command-line tool to read working hours from your calendar, sum them up, and push them to absence.io. It provides a convenient way to manage your working hours without manual calculation.

## Installation

You can install `WorkTimeUtil` using [Homebrew](https://brew.sh/) by running:

```sh
brew tap emanuelmairoll/homebrew-tap
brew install worktimeutil
```

## Usage

WorkTimeUtil has three main commands: `calculate`, `push`, and `config`.

### Calculate

Calculate working hours for a specific time period.

```sh
worktimeutil calculate [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
```

Arguments:

- `W`: Current week
- `W<n>`: Week number `n`
- `W<n>/<yy>`: Week number `n` of the year `yy`
- `M`: Current month
- `M<n>`: Month number `n`
- `M<n>/<yy>`: Month number `n` of the year `yy`

There is also a shorthand provided:

```sh
wtc [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
```

### Push

Push working hours to absence.io for a specific time period.

```sh
worktimeutil push [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
```

Arguments are the same as for the `calculate` command.

There is also a shorthand provided:

```sh
wtp [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
```

### Config

Set configuration values.

```sh
worktimeutil config [key] [value]
```

- `key`: The configuration key to set (e.g., `absenceIOCreds`).
- `value`: The value to set for the specified key.

## Configuration

You can set the following configuration values:

- `absenceIOCreds`: Set your absence.io API credentials in the format `<ID>:<KEY>`. This is required for the `push` command.
- `workHoursPerWeek`: Set your expected work hours per week. The default value is 38.5.
- `removeLunchBreak`: Set to `true` to remove lunch break duration from working hour calculation, or `false` to include it. The default value is `false`.