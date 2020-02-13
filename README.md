Pagantis OsTicket
===============

# Introduction

Docker image for running pagantis version of osTicket based on 1.14.1 of [osTicket](http://osticket.com/).

osTicket is being served by [nginx](http://wiki.nginx.org/Main) using
[PHP-FPM](http://php-fpm.org/) with PHP 7.3.
PHP [mail](http://php.net/manual/en/function.mail.php) function is configured to use
[msmtp](http://msmtp.sourceforge.net/) to send out-going messages.

# Quick Start
Easy, just run:
```bash
docker-compose up -d
```

Wait arround 10s for the installation to complete then browse
`http://localhost:9082/scp/`. Login with default admin user & password:

* username: **admin**
* password: **admin**

Now configure as required. If you are intending on using this image in production, please make sure
you change the passwords above and read the rest of this documentation!

Note: osTicket automatically redirects `http://localhost:8080/scp` to `http://localhost/scp/`.
Either serve this on port 80 or don't omit the trailing slash after `scp/`!
