Arkiv
=====

Easy-to-use backup and archive tool.

Arkiv is designed to **backup** local files and [MySQL](https://www.mysql.com/) databases, and **archive** them on [Amazon S3](https://aws.amazon.com/s3/) and [Amazon Glacier](https://aws.amazon.com/glacier/).  
Backup files are removed (locally and from Amazon S3) after defined delays.

Arkiv could backup your data on a **daily** or an **hourly** basis (you can choose which day and/or which hours it will be launched).  
It is written in pure shell, so it can be used on any Unix/Linux machine.

Arkiv was created by [Amaury Bouchard](http://amaury.net) and is [open-source software](#what-is-arkivs-license).


************************************************************************

Table of contents
-----------------

1. [How it works](#1-how-it-works)
   1. [General Idea](#11-general-idea)
   2. [Steb-by-step](#12-step-by-step)
2. [Installation](#2-installation)
   1. [Prerequisites](#21-prerequisites)
   2. [Source installation](#22-source-installation)
   3. [Configuration](#23-configuration)
3. [Frequently Asked Questions](#3-frequently-asked-questions)
   1. [Cost and license](#31-cost-and-license)
   2. [Configuration](#32-configuration)
   3. [Files backup](#33-files-backup)
   4. [Output and log](#34-output-and-log)
   5. [Database backup](#35-database-backup)
   6. [Crontab](#36-crontab)
   7. [Miscellaneous](#37-miscellaneous)


************************************************************************

## 1. How it works

### 1.1 General idea

- Generate backup data from local files and databases.
- Store data on the local drive for a few days/weeks, in order to be able to restore fresh data very quickly.
- Store data on Amazon S3 for a few weeks/months, if you need to restore them easily.
- Store data on Amazon Glacier for ever. It's an incredibly cheap storage that should be used instead of Amazon S3 for long-term conservancy.

Data are deleted from the local drive and Amazon S3 when the configured delays are reached.   
If your data are backed up multiple time per day (not just every day), it's possible to define a fine-grained purge of the files stored on the local drive and on Amazon S3.   
For example, it's possible to:
- remove half the backups after two days
- keep only 2 backups per day after 2 weeks
- keep 1 backup per day after 3 weeks
- remove all files after 2 months

The same kind of configuration could be defined for Amazon S3 archives.

### 1.2 Step-by-step

**Starting**
1. Arkiv is launched every day (or every hour) by Crontab.
2. It creates a directory dedicated to the backups of the day (or the backups of the hour).

**Backup**
1. Each configured path is `tar`'ed and compressed, and the result is stored in the dedicated directory.
2. *If MySQL backups are configured*, the needed databases are dumped and compressed, in a sub-directory.
3. *If encryption is configured*, the backup files are encrypted.
4. Checksums are computed for all the generated files. These checksums are useful to verify that the files are not corrupted after being transfered over a network.

**Archiving**
1. *If Amazon Glacier is configured*, all the generated backup files (not the checksums file) are sent to Amazon Glacier. For each one of them, a JSON file is created with the response's content; these files are important, because they contain the *archiveId* needed to restore the file.
2. *If Amazon S3 is configured*, the whole directory (backup files + checksums file + Amazon Glacier JSON files) is copied to Amazon S3.

**Purge**
1. After a configured delay, backup files are removed from the local disk drive.
2. *If Amazon S3 is configured*, all backup files are removed from Amazon S3 after a configured delay. The checksums file and the Amazon Glacier JSON files are *not* removed, because they are needed to restore data from Amazon Glacier and check their integrity.


************************************************************************

## 2. Installation

### 2.1 Prerequisites

#### 2.1.1 Basic
Several tools are needed by Arkiv to work correctly. They are usually installed by default on every Unix/Linux distributions.
- A not-so-old [`bash`](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) Shell interpreter located on `/bin/bash` (mandatory)
- [`tar`](https://en.wikipedia.org/wiki/Tar_(computing)) for files concatenation (mandatory)
- [`gzip`](https://en.wikipedia.org/wiki/Gzip), [`bzip2`](https://en.wikipedia.org/wiki/Bzip2), [`xz`](https://en.wikipedia.org/wiki/Xz) or [`zstd`](https://en.wikipedia.org/wiki/Zstd) for compression (at least one)
- [`openssl`](https://en.wikipedia.org/wiki/OpenSSL) for encryption (optional)
- [`sha256sum`](https://en.wikipedia.org/wiki/Sha256sum) for checksums computation (mandatory)
- [`tput`](https://en.wikipedia.org/wiki/Tput) for [ANSI text formatting](https://en.wikipedia.org/wiki/ANSI_escape_code) (optional: can be manually deactivated; automatically deactivated if not installed)

To install these tools on Ubuntu:
```shell
# apt-get install tar gzip bzip2 xz-utils openssl coreutils ncurses-bin
```

#### 2.1.2 Encryption
If you want to encrypt the generated backup files (stored locally as well as the ones archived on Amazon S3 and Amazon Glacier), you need to create a symmetric encryption key.

Use this command to do it (you can adapt the destination path):
```shell
# openssl rand 32 -out ~/.ssh/symkey.bin
```

#### 2.1.3 MySQL
If you want to backup MySQL databases, you have to install [`mysqldump`](https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html) or [`xtrabackup`](https://www.percona.com/software/mysql-database/percona-xtrabackup).

To install `mysqldump` on Ubuntu:
```shell
# apt-get install mysql-client
```

To install `xtrabackup` on Ubuntu (see [documentation](https://www.percona.com/doc/percona-xtrabackup/2.4/installation/apt_repo.html)):
```shell
# wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
# dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
# apt-get update
# apt-get install percona-xtrabackup-24
```

#### 2.1.4 Amazon Web Services
If you want to archive the generated backup files on Amazon S3/Glacier, you have to do these things:
- Create a dedicated bucket on [Amazon S3](https://aws.amazon.com/s3/).
- If you want to archive on [Amazon Glacier](https://aws.amazon.com/glacier/), create a dedicated vault in the same datacenter.
- Create an [IAM](https://aws.amazon.com/iam/) user with read-write access to this bucket and this vault (if needed).
- Install the [AWS-CLI](https://aws.amazon.com/cli/) program and [configure it](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).

Install AWS-CLI on Ubuntu:
```shell
# apt-get install awscli
```

Configure the program (you will be asked for the AWS user's access key and secret key, and the used datacenter):
```shell
# aws configure
```


### 2.2 Source Installation

Get the last version:
```shell
# wget https://github.com/Amaury/Arkiv/archive/0.12.0.zip -O Arkiv-0.12.0.zip
# unzip Arkiv-0.12.0.zip

or

# wget https://github.com/Amaury/Arkiv/archive/0.12.0.tar.gz -O Arkiv-0.12.0.tar.gz
# tar xzf Arkiv-0.12.0.tar.gz
```


### 2.3 Configuration

```shell
# cd Arkiv-0.12.0
# ./arkiv config
```

Some questions will be asked about:
- If you want a simple installation (one backup per day, everyday, at midnight).
- The local machine's name (will be used as a subdirectory of the S3 bucket).
- The used compression type.
- If you want to encrypt the generated backup files.
- Which files must be backed up.
- Everything about MySQL backup (SQL or binary backup, which databases, host/login/password for the connection).
- Where to store the compressed files resulting of the backup.
- Where to archive data on Amazon S3 and Amazon Glacier (if you want to).
- When to purge files (locally and on Amazon S3).

Finally, the program will offer you to add the Arkiv execution to the user's crontab.


************************************************************************

## 3. Frequently Asked Questions

### 3.1 Cost and license

#### What is Arkiv's license?
Arkiv is licensed under the terms of the [MIT License](https://en.wikipedia.org/wiki/MIT_License), which is a permissive open-source free software license.

More in the file `COPYING`.

#### How much will I pay on Amazon S3/Glacier?
You can use the [Amazon Web Services Calculator](https://calculator.s3.amazonaws.com/index.html) to estimate the cost depending of your usage.


### 3.2 Configuration

#### How to choose the compression type?
You can use one of the four common compression tools (`gzip`, `bzip2`, `xz`, `zstd`).

Usually, you can follow these guidelines:
- Use `zstd` if you want the best compression and decompression speed.
- Use `xz` if you want the best compression ratio.
- Use `gzip` or `bzip2` if you want the best portability (`xz` and `zstd` are younger and less widespread).

Here are some helpful links:
- [Gzip vs Bzip2 vs XZ Performance Comparison](https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/)
- [Quick Benchmark: Gzip vs Bzip2 vs LZMA vs XZ vs LZ4 vs LZO](https://catchchallenger.first-world.info/wiki/Quick_Benchmark:_Gzip_vs_Bzip2_vs_LZMA_vs_XZ_vs_LZ4_vs_LZO)
- [Zstandard presentation and benchmarks](https://facebook.github.io/zstd/)

The default usage is `zstd`, because it has the best compression/speed ratio.

#### I choose simple mode configuration (one backup per day, every day). Why is there a directory called "00:00" in the backup directory of the day?
This directory means that your Arkiv backup process is launched at midnight.

You may think that the backed up data should have been stored directly in the directory of the day, without a sub-directory for the hour (because there is only one backup per day). But if someday you'd want to change the configuration and do many backups per day, Arkiv would have trouble to manage purges.

#### How to execute Arkiv with different configurations?
You can add the path to the configuration file as a parameter of the program on the command line.

To generate the configuration file:
```shell
# ./arkiv config --config=/path/to/config/file
or
# ./arkiv config -c /path/to/config/file
```

To launch Arkiv:
```shell
# ./arkiv exec --config=/path/to/config/file
or
# ./arkiv exec -c /path/to/config/file
```

You can modify the Crontab to add the path too.

#### Is it possible to use a public/private key infrastructure for the encryption functionnality?
It is not possible to encrypt data with a public key; OpenSSL's [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure) isn't designed to encrypt large data. Encryption is done using an 256 bits AES algorithm, which is symmetrical.  
To ensure that only the owner of a private key would be able to decrypt the data, without transfering this key, you have to encrypt the symmetric key using the public key, and then send the encrypted key to the private key's owner.

Here are the steps to do it (key files are usually located in `~/.ssh/`).

Create the symmetric key:
```shell
# openssl rand 32 -out symkey.bin
```

Convert the public and private keys to PEM format (usually people have keys in RSA format, using them with [SSH](https://en.wikipedia.org/wiki/Secure_Shell)):
```shell
# openssl rsa -in id_rsa -outform pem -out id_rsa.pem
# openssl rsa -in id_rsa -pubout -outform pem -out id_rsa.pub.pem
```

Encrypt the symmetric key with the public key:
```shell
# openssl rsautl -encrypt -inkey id_rsa.pub.pem -pubin -in symkey.bin -out symkey.bin.encrypt
```

To decrypt the encrypted symmetric key using the private key:
```shell
# openssl rsautl -decrypt -inkey id_rsa.pem -in symkey.bin.encrypt -out symkey.bin 
```

To decrypt the data file:
```shell
# openssl enc -d -aes-256-cbc -in data.tgz.encrypt -out data.tgz -pass file:symkey.bin
```

#### Why is it not possible to archive on Amazon Glacier without archiving on Amazon S3?
When you send a file to Amazon Glacier, you get back an *archiveId* (file's unique identifier). Arkiv take this information and write it down in a file; then this file is copied to Amazon S3.
If the *archiveId* is lost, you will not be able to get the file back from Amazon Glacier. An archived file that you can't restore is useless. Even if it's possible to get the list of archived files from Amazon Glacier, it's a slow process; it's more flexible to store *archive identifiers* in Amazon S3 (and the cost to store them is insignificant).


### 3.3 Files backup

#### How to exclude files and directories from archives?
Arkiv provides several ways to exclude content from archives.

First of all, it follows the [CACHEDIR.TAG](https://bford.info/cachedir/) standard. If a directory contains a `CACHEDIR.TAG` file, it will be added to the archive, as well as the `CACHEDIR.TAG` file, but not its other files and subdirectories.

If you want to exclude the content of a directory in a way similar of the previous one, but you don't want to create a `CACHEDIR.TAG` file (to avoid exclusion of the directory by other programs), you can create an empty `.arkiv-exclude` file in the directory. The directory and the `.arkiv-exclude` will be added to the archive (to keep track of the folder, with the information of the subcontent exclusion), but not the other files and subdirectories contained in the given directory.

If you want to exclude specific files of a directory, you can create a `.arkiv-ignore` file in the directory, and write a list of exclusion patterns into it. These patterns will be used to exclude files and subdirectories directly stored in the given directory.

If you create a `.arkiv-ignore-recursive` file in a directory, patterns will be read from this file to define recursive exclusions in the given directory and all its subdirectories.


### 3.4 Output and log

#### Is it possible to execute Arkiv without any output on STDOUT and/or STDERR?
Yes, you just have to add some options on the command line:
- `--no-stdout` (or `-o`) to avoid output on STDOUT
- `--no-stderr` (or `-e`) to avoid output on STDERR

You can use these options separately or together.

#### How to write the execution log into a file?
You can use a dedicated parameter:
```shell
# ./arkiv exec --log=/path/to/log/file
or
# ./arkiv exec -l /path/to/log/file
```

It will not disable output on the terminal. You can use the options `--no-stdout` and `--no-stderr` for that (see previous answer).

#### How to write log to syslog?
Add the option `--syslog` (or `-s`) on the command line or in the Crontab command.

#### How to get pure text (without ANSI commands) in Arkiv's log file?
Add the option `--no-ansi` (or `-n`) on the command line or in the Crontab command. It will act on terminal output as well as log file (see `--log` option above) and syslog (see `--syslog` option above).

#### I open the Arkiv log file with less, and it's full of strange characters
Unlike `more` and `tail`, `less` doesn't interpret ANSI text formatting commands (bold, color, etc.) by default.  
To enable it, you have to use the option `-r` or `-R`.


### 3.5 Database backup

#### What kind of database backups are available?
Arkiv could generate two kinds of database backups:
- SQL backups created using [`mysqldump`](https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html).
- Binary backups using [`xtrabackup`](https://www.percona.com/software/mysql-database/percona-xtrabackup).

There is two types of binary backups:
- Full backups; the server's files are entirely copied.
- Incremental backups; only the data modified since the last backup (full or incremental) are copied.

You must do a full backup before performing any incremental backup.

#### Which databases and table engines could be backed up?
If you choose SQL backups (using `mysqldump`), Arkiv can manage any table engine supported by [MySQL](https://www.mysql.com/), [MariaDB](https://mariadb.org/) and [Percona Server](https://www.percona.com/software/mysql-database/percona-server).

If you choose binary backups (using `xtrabackup`), Arkiv can handle:
- MySQL (5.1 and above) or MariaDB, with InnoDB, MyISAM and XtraDB tables.
- Percona Server with XtraDB tables.

Note that MyISAM tables can't be incrementally backed up. They are copied entirely each time an incremental backup is performed.

#### Are binary backups prepared for restore?
No. Binary backups are done using `xtrabackup --backup`. The `xtrabackup --prepare` step is not done to save time and space. You will have to do it when you want to restore a database (see below).

#### How to define a full binary backup once per day and an incremental backup every other hours?
You will have to create two different configuration files and add Arkiv in Crontab twice: once for the full backup (everyday at midnight for example), and once for the incremental backups (every hours except midnight).

You need both executions to use the same LSN file. It will be written by the full backup, and read and updated by each incremental backups.

The same process could be used with any other frequency (for example: full backups once a week and incremental backups every other days).

#### How to restore a SQL backup?
Arkiv generates one SQL file per database. You have to extract the wanted file and process it in your database server:
```shell
# unxz /path/to/database_sql/database.sql.xz
# mysql -u username -p < /path/to/database_sql/database.sql
```

#### How to restore a full binary backup without subsequent incremental backups?
To restore the database, you first need to extract the data:
```shell
# tar xJf /path/to/database_data.tar.xz
or
# tar xjf /path/to/database_data.tar.bz2
or
# tar xzf /path/to/database_data.tar.gz
```

Then you must prepare the backup:
```shell
# xtrabackup --prepare --target-dir=/path/to/database_data
```

Please note that the MySQL server must be shut down, and the 'datadir' directory (usually `/var/lib/mysql`) must be empty. On Ubuntu:
```shell
# service mysql stop
# rm -rf /var/lib/mysql/*
```

Then you can restore the data:
```shell
# xtrabackup --copy-back --target-dir=/path/to/database_data
```

Files' ownership must be given back to the MySQL user (usually `mysql`):
```shell
# chown -R mysql:mysql /var/lib/mysql
```

Finally you can restart the MySQL daemon:
```shell
# service mysql start
```

#### How to restore a full + incrementals binary backup?
Let's say you have a full backup (located in `/full/database_data`) and three incremental backups (located in `/inc1/database_data`, `/inc2/database_data` and `/inc3/database_data`), and you have already extracted the backed up files (see previous answer).

First, you must prepare the full backup with the additional `--apply-log-only` option:
```shell
# xtrabackup --prepare --apply-log-only --target-dir=/full/database_data
```

And then you prepare using all incremental backups in their creation order, **except the last one**:
```shell
# xtrabackup --prepare --apply-log-only --target-dir=/full/database_data --incremental-dir=/inc1/database_data
# xtrabackup --prepare --apply-log-only --target-dir=/full/database_data --incremental-dir=/inc2/database_data
```

Data preparation of the last incremental backup is done without the `--apply-log-only` option:
```shell
# xtrabackup --prepare --target-dir=/full/database_data --incremental-dir=/inc3/database_data
```

Once every backups have been merged, the process is the same than for a full backup:
```shell
# service mysql stop
# rm -rf /var/lib/mysql/*
# xtrabackup --copy-back --target-dir=/path/to/database_data
# chown -R mysql:mysql /var/lib/mysql
# service mysql start
```


### 3.6 Crontab

#### On simple mode (one backup per day, every day at midnight), how to set up Arkiv to be executed at another time than midnight?
You just have to edit the configuration file of the user's [Cron table](https://en.wikipedia.org/wiki/Cron):
```shell
# crontab -e
```

#### How to execute pre- and/or post-backup scripts?
See the previous answer. You just have to add these scripts before and/or after the Arkiv program in the Cron table.

#### Is it possible to backup more often than every hours?
No, it's not possible.

#### I want to have colors in the Arkiv log file when it's launched from Crontab, as well as when it's launch from the command line
The problem comes from the Crontab environment, which is very minimal.  
You have to set the `TERM` environment variable from the Crontab. It is also a good idea to define the `MAILTO` and `PATH` variables.

Edit the Crontab:
```shell
# crontab -e
```

And add these three lines at its beginning:
```shell
TERM=xterm
MAILTO=your.email@domain.com
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

#### How to receive an email alert when a problem occurs?
Add a `MAILTO` environment variable at the beginning of your Crontab. See the previous answer.


### 3.7 Miscellaneous

#### How to report bugs?
[Arkiv issues tracker](https://github.com/Amaury/Arkiv/issues)

#### Why is Arkiv compatible only with Bash interpreter?
Because the `read` buitin command has a `-s` parameter for silent input (used for encryption passphrase and MySQL password input without showing them), unavailable on `dash` or `zsh` (for example).

#### Arkiv looks like Backup-Manager
Yes indeed. Both of them wants to help people to backup files and databases, and archive data in a secure place.

But Arkiv is different in several ways:
- It can manage hourly backups.
- It can transfer data on Amazon Glacier for long-term archiving.
- It can manage complex purge policies.
- The configuration process is simpler (you answer to questions).
- Written in pure shell, it doesn't need a Perl interpreter.

On the other hand, [Backup-Manager](https://github.com/sukria/Backup-Manager) is able to transfer to remote destinations by SCP or FTP, and to burn data on CD/DVD.

