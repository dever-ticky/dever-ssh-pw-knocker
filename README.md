# dever-ssh-pw-knocker

tool used for checking if password authentication is allowed on ssh (port 22) connections on a list of remote machines

accepts a file of "IP hostname" pairs as input (e.g. /etc/hosts)

does a 3-step check:
- checks with ping if host online
- checks with nc if port 22 open
- checks with ssh if password (keyboard-interactive) is allowed

e.g. usage: ./ssh-pw-knocker.sh /etc/hosts
