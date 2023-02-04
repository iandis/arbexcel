# ARB Excel

For reading, creating and updating ARB files from XLSX files.

## Install

```bash
pub global activate arbxcel
```

## Basic Usage

```bash
pub global run arbxcel

arbxcel [FLAGS] [OPTIONS] path/to/file/name

FLAGS
-n, --new      New translation sheet
-a, --arb      Export to ARB files
-e, --excel    Import ARB files to sheet

OPTIONS
-s, --sheet         Main sheet name (defaults to "Main")
-p, --placeholders  Sheet name for predefined placeholders
```

Creates an XLSX template file.

```bash
pub global run arbxcel -n app.xlsx
```

Generates ARB files from a XLSX file.

```bash
pub global run arbxcel -a app.xlsx
```

Creates an XLSX file from ARB files.

```bash
pub global run arbxcel -e app_en.arb
```

## Usage with Flutter Localizations

```bash
dart run arbxcel:excel10n [FLAGS] [OPTIONS] path/to/file/name

FLAGS
-h, --help                              Show usage information

OPTIONS
--path                                  Path containing the localization files (*.arb and *.xlsx files).
                                        Defaults to "lib/src/l10n"
-e, --excel-source-file                 Excel file for generating the localization files.
                                        Defaults to "app.xlsx"
-s, --excel-main-sheet-name             Target Excel main sheet name.
                                        Defaults to "Main"
-p, --excel-placeholder-sheet-name      Target Excel placeholder sheet name.
                                        Defaults to empty
-t, --template-arb-file                 Template ARB file for generating the localization files.
                                        Defaults to "app_en.arb"
-o, --output-localization-file          Output localization file for generating the localization files.
                                        Defaults to "app_localizations.dart"
-f, --flutter-path                      Path to the flutter SDK.
                                        Defaults to system's env path to flutter
```

## Predefined Placeholders

If you have multiple same placeholders, you can utilize the predefined placeholders feature by creating a separate excel sheet that has columns of "key" and its corresponding values in each language.

**Note**: each key can **ONLY** contain alphanumeric (a-Z, 0-9) and underscores ("\_")

Example:
| key | en | id |
|-------|-----------------------------|-----------------------------|
| date1 | "DateTime", "format": "yMd" | "DateTime", "format": "dMy" |

To use it on the main sheet:
| name | description | placeholders | en | id |
|-----------|------------------------|----------------------------|-----------------|---------------------------|
| payAtDate | Text for pay with date | {"date": {"type": $date1}} | Pay when {date} | Bayar pada tanggal {date} |

Generating will produce:

`en.arb`

```json
{
  "payAtDate": "Pay when {date}",
  "@payAtDate": {
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  }
}
```

`id.arb`

```json
{
  "payAtDate": "Bayar pada tanggal {date}",
  "@payAtDate": {
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "dMy"
      }
    }
  }
}
```
