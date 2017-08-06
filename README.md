Arkiv
=====

Simple file archiver, designed to backup local files and MySQL databases and archive them on Amazon S3.

Every day:
1. Create backup files from local paths.
2. Dump MySQL databases.
3. Archive files to Amazon S3.
4. Purge local archive files after a defined delay.
5. Purge archive files stored on Amazon S3 after a defined delay.

Prerequisites
-------------

If you want to archive the generated backup files on Amazon S3, you need to do 3 things:
- Create a dedicated bucket on [Amazon S3](https://aws.amazon.com/s3/).
- Create an [IAM](https://aws.amazon.com/iam/) user with read-write access to this bucket.
- Install the [AWS-CLI](https://aws.amazon.com/cli/) program and [configure it](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).

Install on Ubuntu:
```shell
# apt-get install awscli
```

Configuration of the program:
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
- Where to archive data on Amazon S3.
- When to purge files (locally and on Amazon S3).

Finally, the program could add the backup/archive/purge process to the user's crontab.

