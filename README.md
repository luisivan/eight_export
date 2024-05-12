# eight_export

Exports your average HRV and BPM per day from Eight Sleep to a CSV file, which then you can easily import into Apple Health.

### Installation

It's a Crystal program, so you just need to download and run the binary (`eight_export`).

## Usage

Create `.auth.yml` like this:

```
email: your@email.com
password: securepassword123
timezone: America/Grenada
```

Then run the program like this:

```sh
eight_export -f 2024-01-01
```

Default file path is `entries.csv` and by default it looks for a date in the latest row and exports entries from that date. So, the first time you run it, you probably want to specify a date. From then onwards, it overwrites the file every time with the new entries.

The use case is to export data to a CSV in iCloud, and then import the CSV to Apple Health every day/week.

```sh
Usage: eight_export [arguments]
    -f DATE, --from=DATE             Export from date (in format %Y-%m-%d)
    -o FILE, --output=FILE           Export to file path
    -h, --help                       Show this help
```
