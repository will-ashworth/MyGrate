# MyGration™

## IMPORTANT

_Consider the below copy placeholder. The script is undergoing testing right now, and I'll update shortly. It would be wise to test this on a separate database for the moment. Working through most of the bugs right now, and should have something up soon if all goes well!_

## Overview

MyGration™ is a MySQL transport script written in Bash to assist with migrating data between two systems. At its core, it's a pretty simple concept many of us are already familiar with. The issue is that manually doing this is inefficient, and time consuming. This script aims to provide a flexible way to semi-automate a lot of the mundane tediousness you already encounter in your day-to-day.

This started out as a self-used solution where everything was local to my machine. It had hard-coded variables of information that I'm now rewriting to streamline this a bit more for others' use.

While MyGration™ has been specifically tested on `MySQL 14.14 Distrib 5.7.13`, this should also work with MariaDB. If any issues, please see the "Support" section below.

Initial testing has been done on Linux and Mac OS.

## Getting Started
...

## Support

Something gone wrong? Maybe I can help. Please create an issue on Github, and provide as much detail about the problem as you possibly can.

Please keep in mind that this is a personal side project, and I'll maintain it as I can. I have a family, and a job; and MyGration™ doesn't necessarily come first.

## How you can help

If you're adept with Bash, and feel like you might be able to contribute, you are welcome to fork and get your hands dirty.

Also, if you have personally tested on a particular platform, I'd love to somehow incorporate that into a file or this README so others know if the script works in their environment.

## Roadmap
- Conversion to support include files, rather than one large file (more modular structure to the script)
- General support for Microsoft Windows operating system
- Documentation for aliases in `~/.bash_profile` to automate even more of your development workflow
- Option to delete backup files older than xx days
