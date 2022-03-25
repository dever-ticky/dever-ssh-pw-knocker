# dever-ssh-pw-knocker

tool used for checking if password authentication is allowed on ssh (port 22) connections on a list of remote machines

accepts a file of "IP hostname" pairs as input (e.g. /etc/hosts)
- ignores commented lines `# e.g.commented line`
- ignores unmatching lines that don't follow the "IP hostname" rule

e.g. input file:
```
127.0.0.1	localhost
127.0.1.1	mypc
192.168.1.2 desktop
192.168.1.30 laptop
```

does a 3-step check:
- checks with ping if host online
- checks with nc if port 22 open
- checks with ssh if password (keyboard-interactive) is allowed

e.g. usage:
```
./ssh-pw-knocker.sh /path/to/file
./ssh-pw-knocker.sh /etc/hosts > ~/logfile.out
```
