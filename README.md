Arkiv
=====

Easy-to-use backup and archive tool.

Arkiv is designed to **backup** local files and [MySQL](https://www.mysql.com/) databases, and **archive** them on [Amazon S3](https://aws.amazon.com/s3/) and [Amazon Glacier](https://aws.amazon.com/glacier/).
Backup files are removed (locally and from Amazon S3) after defined delays.

It is written in pure shell, so it can be used on any Unix/Linux machine.


How it works
------------

The whole idea is:
- Generate backup data from local files and databases.
- Store data on the local drive for a few days, in order to be able to restore fresh data very quickly.
- Store data on Amazon S3 for a few weeks, if you need to restore them easily.
- Store data on Amazon Glacier for ever. It's an incredibly cheap storage that should be used instead of Amazon S3 for long-term conservancy.

1. **Starting**
   1. Arkiv is launched every day by Crontab.
   2. It creates a directory dedicated to the backups of the day.
2. **Backup**
   1. Each configured path is `tar`'ed and compressed, and the result is stored in the dedicated directory.
   2. *If MySQL backups are configured*, the needed databases are dumped and compressed, in the same directory.
   3. Checksums are computed for all the generated files. These checksums are useful to verify that files are not corrupted after being transfered over a network.
3. **Archiving**
   1. *If Amazon Glacier is configured*, all the generated backup files (not the checksums file) are sent to Amazon Glacier. For each one of them, a JSON file is created with the answer; these files are important, because they contain the archiveId needed to restore the file.
   2. *If Amazon S3 is configured*, the whole directory (backup files + checksums file + Amazon Glacier JSON files) is copied to Amazon S3.
4. **Purge**
   1. After a configured delay, backup files are removed from the local disk drive.
   2. *If Amazon S3 is configured*, all backup files are removed from Amazon S3 after a configured delay. The checksums file and the Amazon Glacier JSON files are *not* removed, because they are needed to restore data from Amazon Glacier and check their integrity.


Prerequisites
-------------

### Basic

Several tool are needed by Arkiv to work correctly. They are usually installed by default on every Unix/Linux distributions.
- A not-so-old Shell interpreter (like [`dash`](https://en.wikipedia.org/wiki/Almquist_shell) or [`bash`](https://en.wikipedia.org/wiki/Bash_(Unix_shell))) available on `/bin/sh`.
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
- If you want to archive on Amazon Glacier, create a dedicated vault on [Amazon Glacier](https://aws.amazon.com/glacier/) (in the same datacenter).
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


Install
-------

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
- The local machine's name (will be used as a subdirectory of the S3 bucket).
- Where to store the compressed files resulting of the backup.
- Which files must be backed up.
- Everything about MySQL backup (which databases, host/login/password for the connection).
- Where to archive data on Amazon S3 and Amazon Glacier (if you want to).
- When to purge files (locally and on Amazon S3).

Finally, the program could add the backup/archive/purge process to the user's crontab.


Frequently Asked Questions
--------------------------

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

### How to set up Arkiv to be executed at another time than midnight?
You just have to edit the configuration file of the user's [Cron table](https://en.wikipedia.org/wiki/Cron):
```shell
# crontab -e
```

### How to execute pre- and/or post-backup scripts?
See the previous answer. You just have to add these scripts before and/or after the Arkiv program in the Cron table.

### Arkiv looks like Backup-Manager
Yes indeed. Both of them wants to help people to backup files and databases, and archive data in a secure place.

But Arkiv is different in several ways:
- Written in pure shell, it doesn't need a Perl interpreter.
- The configuration process is simpler (you answer to questions).
- Transfer to Amazon Glacier for long-term archiving.

On the other hand, [Backup-Manager](https://github.com/sukria/Backup-Manager) is able to transfer to remote destinations by SCP or FTP.

