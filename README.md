# MyGrate™

## Overview

MyGrate™ is a MySQL migration script written in Bash to assist with moving databases between two systems. At its core, it's a pretty simple concept many of us are already familiar with. The issue is that manually doing this is inefficient, and time consuming. This script aims to provide a flexible way to semi-automate a lot of the mundane tediousness you may already encounter in your day-to-day.

Much of the script is dependency related, and guided. So if the script needs something in order to work, and detects along the way that it doesn't have it...it'll nag you for it, and help you set everything up just right.

This started out as a self-used solution where everything was local to my machine. It had hard-coded variables of information that I'm now rewriting to streamline this a bit more for others' use.

While MyGrate™ has been specifically tested on `MySQL 14.14 Distrib 5.7.13`, this should also work with MariaDB. If any issues, please see the "Support" section below.

Initial testing has been done on Linux and Mac OS.

## Getting Started

### Clone this repo

	git clone https://github.com/will-ashworth/MyGrate.git
	cd MyGrate

### Set executable permissions on MyGrate

	chmod u+x mygrate

### Create your config file

    cp -p mygrate-config-sample ~/.mygrate-config

### Let's see what this thing can do!

	./mygrate -h

### Setup database hosts for the first time

This is where it gets interesting. I'm using `mysql_config_editor` in the script to manage/house credentials. This allows you to truly run this passwordless.

The script is extremely flexible. You can either always pass cli parameters to the script (host, port, database, password, etc)... or only sometimes. It's totally up to you, and how you're using this script (ie., via cron, manually in the cli, etc) will determine which route you want to take.

#### Authentication options

##### Pass the credentials via the cli

Unless you opt for the second option below, you'll need to pass these at least once.

For example:

	./mygrate --source "remote" \
	--remotehost "my.remoteho.st" \
	--remotedb "xxxxxx" \
	--remoteport "xxxxxx" \
	--remoteuser "xxxxxx" \
	--remotepass "xxxxxx" \
	--localhost "localhost" \
	--localdb "xxxxxx" \
	--localport "xxxxxx" \
	--localuser "xxxxxx" \
	--localpass "xxxxxx" 

This would cause the script to prompt you to create this access file, if it doesn't already exist for the given you hostnames. If one or both already match, it skips the appropriate step...knowing you already have a saved login profile in MySQL locally for one or more of the hostnames.

###### How do I know if I have a saved profile?

To check if you already have a saved profile for one of your MySQL endpoints, you can test like this:

	mysql_config_editor print --login-path=localhost
	
This will show you the saved credentials (if any) that already exist for `localhost` as a server/host. Similarly, you can check other hosts as well via the same method:

	mysql_config_editor print --login-path=someother.host.com

##### Setup your own credentials beforehand

If you don't want your credentials being passed through the script itself at the command line (and being saved in your history), just run `mysql_config_editor` before running this script. This way, your credentials are already saved on your system.

The script uses `--login-path=some.hostname.here`. So if you do choose to setup your credentials externally of the script, make sure you're using the hostname in your saved credentials as you will also be using with the script. Both of the following cli parameters will be matching your login path hostname.

	--remotehost
	--localhost

[Learn more about how mysql_config_editor works](http://dev.mysql.com/doc/refman/5.7/en/mysql-config-editor.html)

For example, having already created these credentials, you can simplify your command very much now:

	./mygrate --source "remote" \
	--remotehost "my.remoteho.st" \
	--remotedb "xxxxxx" \
	--localhost "localhost" \
	--localdb "xxxxxx"

We don't need the port, username, or password anymore; because they're stored locally; and MySQL (through this script) will simply read from those files.

## Usage examples

### Copy local to remote

	./mygrate --source "local" --remotehost "my.remoteho.st" --remotedb "xxxxxx" --localhost "localhost" --localdb "xxxxxx"

### Copy remote to local

	./mygrate --source "remote" --remotehost "my.remoteho.st" --remotedb "xxxxxx" --localhost "localhost" --localdb "xxxxxx"

## Taking it a step further

### Bash aliases

If you're so inclined, and want to reduce the amount of typing you'll be doing for repetitive tasks, you're able to automate these longer-form commands with aliases in your `~/.bash_profile`. Just don't forget to `source` your file after you've edited it!

	source ~/.bash_profile

An example may include a common task you handle every day; such as copying a production website's database to your local MySQL installation for local development. So instead of this:

	./mygrate --source "remote" --remotehost "my.production.hostname" --remotedb "production_somewebsite" --localhost "localhost" --localdb "somewebsite"

...you could instead alias it to be like `prod_local_somesite`. In your `~/.bash_profile` file, your alias might look something like this:

	alias prod_local_somesite='/path/to/mygrate --source "remote" --remotehost "my.production.hostname" --remotedb "production_somewebsite" --localhost "localhost" --localdb "somewebsite"'

Similarly, if you wanted to setup an alias for the reversal (local-to-dev) to deploy your local changes to the live server, you could setup another alias like `local_prod_somesite`.

## Support

Something gone wrong? Maybe I can help. Please create an issue on Github, and provide as much detail about the problem as you possibly can.

Please keep in mind that this is a personal side project, and I'll maintain it as I can. I have a family, and a job; and MyGrate™ doesn't necessarily come first.

## How you can help

If you're at all skilled with Bash, and feel like you might be able to contribute, you are welcome to fork this repo and get your hands dirty. I would appreciate the help.

Also, if you have personally tested on a particular platform, I'd love to somehow incorporate that into a file or this README so others know if the script works in their environment.

If you find this useful and want to [buy me a beer or sponsor a date with my fiancé](https://flattr.com/submit/auto?fid=9ze3l6&url=https%3A%2F%2Fgithub.com%2Fwill-ashworth%2FMyGrate), that would be pretty cool.

## Roadmap
- Conversion to support include files, rather than one large file (more modular structure to the script)
- Documentation for aliases in `~/.bash_profile` to automate even more of your development workflow
- Option to delete backup files older than xx days
- General support for Microsoft Windows operating system
