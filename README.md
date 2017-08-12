Arkiv
=====

Easy-to-use backup and archive tool.

Arkiv is designed to **backup** local files and [MySQL](https://www.mysql.com/) databases, and **archive** them on [Amazon S3](https://aws.amazon.com/s3/) and [Amazon Glacier](https://aws.amazon.com/glacier/).  
Backup files are removed (locally and from Amazon S3) after defined delays.

Arkiv could backup your data on a **daily** or an **hourly** basis (you can choose which day and/or which hours it will be launched).  
It is written in pure shell, so it can be used on any Unix/Linux machine.

Arkiv was created by Amaury Bouchard <amaury@amaury.net>.


How it works
------------

### General idea
- Generate backup data from local files and databases.
- Store data on the local drive for a few days/weeks, in order to be able to restore fresh data very quickly.
- Store data on Amazon S3 for a few weeks/months, if you need to restore them easily.
- Store data on Amazon Glacier for ever. It's an incredibly cheap storage that should be used instead of Amazon S3 for long-term conservancy.

If your data are backed up every hour (not just every day), it's possible to define a fine-grained purge of the files stored on the local drive and on Amazon S3. For example, it's possible to remove half the backups after two days, and keep only 2 backups per day after 2 weeks, and keep 1 backup per day after 3 weeks, and remove all files after 2 months. The same could be configured for Amazon S3 archives.

### Step-by-step
**Starting**
1. Arkiv is launched every day (or every hour) by Crontab.
2. It creates a directory dedicated to the backups of the day (or the backups of the hour).

**Backup**
1. Each configured path is `tar`'ed and compressed, and the result is stored in the dedicated directory.
2. *If MySQL backups are configured*, the needed databases are dumped and compressed, in the same directory.
3. Checksums are computed for all the generated files. These checksums are useful to verify that the files are not corrupted after being transfered over a network.

**Archiving**
1. *If Amazon Glacier is configured*, all the generated backup files (not the checksums file) are sent to Amazon Glacier. For each one of them, a JSON file is created with the response's content; these files are important, because they contain the *archiveId* needed to restore the file.
2. *If Amazon S3 is configured*, the whole directory (backup files + checksums file + Amazon Glacier JSON files) is copied to Amazon S3.

**Purge**
1. After a configured delay, backup files are removed from the local disk drive.
2. *If Amazon S3 is configured*, all backup files are removed from Amazon S3 after a configured delay. The checksums file and the Amazon Glacier JSON files are *not* removed, because they are needed to restore data from Amazon Glacier and check their integrity.


Prerequisites
-------------

### Basic

Several tools are needed by Arkiv to work correctly. They are usually installed by default on every Unix/Linux distributions.
- A not-so-old [`bash`](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) Shell interpreter located on `/bin/bash`.
- [`tar`](https://en.wikipedia.org/wiki/Tar_(computing))
- [`gzip`](https://en.wikipedia.org/wiki/Gzip), [`bzip2`](https://en.wikipedia.org/wiki/Bzip2) or [`xz`](https://en.wikipedia.org/wiki/Xz)
- [`sha256sum`](https://en.wikipedia.org/wiki/Sha256sum)
- [`tput`](https://en.wikipedia.org/wiki/Tput)

To install these tools on Ubuntu:
```shell
# apt-get install tar gzip bzip2 xz-utils coreutils ncurses-bin
```

### MySQL

If you want to backup MySQL databases, you have to install the [`mysqldump`](https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html) tool.

To install it on Ubuntu:
```shell
# apt-get install mysql-client
```

### Amazon Web Services

If you want to archive the generated backup files on Amazon S3/Glacier, you have to do these things:
- Create a dedicated bucket on [Amazon S3](https://aws.amazon.com/s3/).
- If you want to archive on [Amazon Glacier](https://aws.amazon.com/glacier/), create a dedicated vault in the same datacenter.
- Create an [IAM](https://aws.amazon.com/iam/) user with read-write access to this bucket and this vault (if needed).
- Install the [AWS-CLI](https://aws.amazon.com/cli/) program and [configure it](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).

Install AWS-CLI on Ubuntu:
```shell
# apt-get install awscli
```

Configuration of the program (you will be asked for the AWS user's access key and secret key, and the used datacenter):
```shell
# aws configure
```


Arkiv Installation
------------------

Clone the GitHub repository:
```shell
# git clone https://github.com/Amaury/Arkiv
```

Configuration:
```shell
# cd Arkiv
# ./arkiv config
```

Some questions will be asked about:
- If you want to backup data every day or every hour.
- The local machine's name (will be used as a subdirectory of the S3 bucket).
- Where to store the compressed files resulting of the backup.
- Which files must be backed up.
- Everything about MySQL backup (which databases, host/login/password for the connection).
- Where to archive data on Amazon S3 and Amazon Glacier (if you want to).
- When to purge files (locally and on Amazon S3).

Finally, the program could add the Arkiv execution to the user's crontab.


Frequently Asked Questions
--------------------------

### I choose simple mode configuration (one backup per day, every day). Why is there a directory called "00:00" in the backup directory of the day?
This directory means that your Arkiv backup process is launched at midnight.

You'd think that the backed up data would have be stored directly in the directory of the day, without a sub-directory for the hour (because there is only one backup per day). But if someday you'd want to change the configuration and do many backups per day, Arkiv would have trouble to manage purges.

### How much will I pay on Amazon S3/Glacier?
You can use the [Amazon Web Services Calculator](https://calculator.s3.amazonaws.com/index.html) to estimate the cost depending of your usage.

### How to choose the compression type?
You can use one of the three common compression tools (`gzip`, `bzip2`, `xz`).

Usually, you can follow these guidelines:
- Use `gzip` if you want the best compression and decompression speed.
- Use `xz` if you want the best compression ratio.
- Use `gzip` or `bzip2` if you want the best portability (`xz` is younger).

Here are some helpful links:
- [Gzip vs Bzip2 vs XZ Performance Comparison](https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/)
- [Quick Benchmark: Gzip vs Bzip2 vs LZMA vs XZ vs LZ4 vs LZO](https://catchchallenger.first-world.info/wiki/Quick_Benchmark:_Gzip_vs_Bzip2_vs_LZMA_vs_XZ_vs_LZ4_vs_LZO)

The default usage is `xz`, because a reduced file size means faster file transfers over a network.

### On simple mode (one backup per day, every day at midnight), how to set up Arkiv to be executed at another time than midnight?
You just have to edit the configuration file of the user's [Cron table](https://en.wikipedia.org/wiki/Cron):
```shell
# crontab -e
```

### How to execute pre- and/or post-backup scripts?
See the previous answer. You just have to add these scripts before and/or after the Arkiv program in the Cron table.

### Is it possible to backup more often than every hours?
No, it's not possible.

### How to execute Arkiv with different configurations?
You can add the path to the configuration file as a parameter of the program on the command line.

To generate the configuration file:
```shell
# ./arkiv config -c /path/to/config/file
or
# ./arkiv config --config=/path/to/config/file
```

To launch Arkiv:
```shell
# ./arkiv exec -c /path/to/config/file
or
# ./arkiv exec --config=/path/to/config/file
```

You can modify the Crontab to add the path too.

### Is it possible to execute Arkiv without any output on STDOUT and/or STDERR?
Yes, you just have to add some options on the command line:
- `--no-stdout` to avoid output on STDOUT
- `--no-stderr` to avoid output on STDERR

You can use these options separately or together.

### Why is it not possible to archive on Amazon Glacier without archiving on Amazon S3?
When a file is sent to Amazon Glacier, you get an *archiveId* (file's unique identifier). Arkiv take this information and write it down in a file; then this file is copied to Amazon S3.
If the *archiveId* is lost, you will not be able to get the file back from Amazon Glacier. An archived file that you can't restore is useless. Even if it's possible to get the list of archived files from Amazon Glacier, it's a slow process; it's more flexible to store *archive identifiers* in Amazon S3 (and the cost to store them is insignificant).

### I want to have colors in the Arkiv log file when it's launched from Crontab, as well as when it's launch from the command line
The problem comes from the Crontab environment, which is very minimal.

You have to set the `TERM` environment variable from the Crontab. It is also a good idea to define the `MAILTO` and `PATH` variables.

Edit the Crontab and add these three lines at its beginning:
```shell
TERM=xterm
MAILTO=your.email@domain.com
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### How to receive an email alert when an error occurs (or even just a warning)?
Add a `MAILTO` environment variable at the beginning of your Crontab.

As said in the previous answer, you can add these three lines:
```shell
TERM=xterm
MAILTO=your.email@domain.com
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### I open the Arkiv log file with less, and it's full of strange characters
Unlike `more` and `tail`, `less` doesn't interpret ANSI commands (bold, color, etc.) by default.
To enable it, you have to use the option `-r` or `-R`.

### How to get pure text (without ANSI commands) in Arkiv's log file?
Add the option `--noansi` (or just `-n`) on the command line or in the Crontab command.

### Why is Arkiv compatible only with Bash interpreter?
Because the `read` buitin command has a `-s` parameter for silent input (used for MySQL password input without showing it), unavailable on `dash` or `zsh` (for example).

### How to report bugs?
[Arkiv issues tracker](https://github.com/Amaury/Arkiv/issues)

### Arkiv looks like Backup-Manager
Yes indeed. Both of them wants to help people to backup files and databases, and archive data in a secure place.

But Arkiv is different in several ways:
- It can manage hourly backups.
- It can transfer data on Amazon Glacier for long-term archiving.
- The configuration process is simpler (you answer to questions).
- Written in pure shell, it doesn't need a Perl interpreter.

On the other hand, [Backup-Manager](https://github.com/sukria/Backup-Manager) is able to transfer to remote destinations by SCP or FTP.

