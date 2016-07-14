# MyGrate™

## Overview

MyGrate™ is a MySQL migration script written in Bash to assist with moving databases between two systems. At its core, it's a pretty simple concept many of us are already familiar with. The issue is that manually doing this is inefficient, and time consuming. This script aims to provide a flexible way to semi-automate a lot of the mundane tediousness you may already encounter in your day-to-day.

This started out as a self-used solution where everything was local to my machine. It had hard-coded variables of information that I'm now rewriting to streamline this a bit more for others' use.

While MyGrate™ has been specifically tested on `MySQL 14.14 Distrib 5.7.13`, this should also work with MariaDB. If any issues, please see the "Support" section below.

Initial testing has been done on Linux and Mac OS.

## Getting Started
...

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
