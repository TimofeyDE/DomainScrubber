# DomainScrubber

## Introduction
This script is designed to update news content entries in a database by removing specific domain references
from the news content. It reads a list of domains from a CSV file and processes each domain by updating the
relevant records in the database to ensure that the content does not contain links to these domains.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Configuration File Format](#configuration-file-format)
- [Contributing](#contributing)
- [Reporting Issues](#reporting-issues)
- [Pull Requests](#pull-requests)

## Features
- **Domain Processing**: Removes domain references from the news content stored in a database.
- **CSV Domain List**: Reads domains from a CSV file, allowing for easy batch processing.
- **Database Integration**: Connects to a MySQL database using a configuration file to perform updates.
- **Error Handling**: Provides clear error messages for common issues such as missing arguments or incorrect
  file formats.

## Requirements
- Bash shell environment
- MySQL client installed and accessible from the command line
- Access to a MySQL database with the relevant news content

## Installation
This script does not require a traditional installation. However, you need to ensure that it has executable permissions.

1. Download the script to your desired directory.
2. Make the script executable by running:

## Usage
To use the script, you will need to provide the path to your CSV file, the database name, and the database
entity (table) where the content is stored. Also, you should specify a configuration file for database
access.
````
./scrubber.sh -f <file_path.csv> -d <database_name> -e <db_entity> [-c <config_file.cnf>]
````

### Options
- `-f <file_path.csv>`: Specifies the path to the CSV file containing the domains to process.
- `-d <database_name>`: Specifies the name of the database containing the news content.
- `-e <db_entity>`: Specifies the database entity (table) where the content is stored.
- `-c <config_file.cnf>`: Specifies the path to the MySQL configuration file containing database access credentials.

### Configuration File Format
The MySQL configuration file should follow the standard `.cnf` format and include at least the
the following information:

```ini
[client]
user = your_database_user
password = your_database_password
host = your_database_host
```

## Contributing
We welcome contributions to this script. If you have improvements or bug fixes, please open a pull request or
an issue in this repository.

## Reporting Issues
Please use the GitHub issue tracker to report any bugs or file feature requests.

## Pull Requests
Ensure your pull request is well-documented and includes any relevant updates to this README for new features
or changes.
