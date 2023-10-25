# s

> Quickly list your .ssh/config connections by group

# Usage

Simply type `s` instead of `ssh`.

![demo](img/demo.gif)

# Requirements

Follow the syntax in [ssh-config.sample](ssh-config.sample).
You don't need to create any group for the script to work.
Hosts outside groups will be listed under "Connections without group".

To create a group, add a comment line starting by `# Group <Group name>`.
Then follow the standard syntax to create your hosts entries.
- Tutorial: https://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/
- Reference: https://linux.die.net/man/5/ssh_config

```
# Group <Group name for group 1>
Host <Friendly name For host 1>
  Hostname my.host
  User root

Host <Friendly name For host 2>
  Hostname my.host

# Group <Group name for group 2>
Host <Friendly name For host 3>
  Hostname my.host
  User root

Host <Friendly name For host 4>
  Hostname my.host
```

# Settings in [tools.sh](../tools.sh)

- Change the location of your `~/.ssh/config` file
- Change the `s` alias command


# Testing

By default the script reads your `~/.ssh/config` file when you type `s`, but you can specify another file, such as the provided sample file:

```
germain@nuc13 UCRT64 /d/Sites/cli-tools
$ parse_ssh_config s/ssh-config.sample
```

The script will list your group entries:

```
Select a group of connections (number):
1) Group 1 Name
2) Group 5 Name
3) Group 2 Name
4) Group 3 Name
5) Group 4 Name
6) Exit
#? 2
Selected group: Group 5 Name
```

The script will list the hosts under the selected group:

```
Now select a host to connect to:
1) friendly_hostname25
2) friendly_hostname24
3) friendly_hostname23
4) friendly_hostname22
Select a host (number) or type '-' to return to groups: 3
```

The script will iniate a SSH connection to the selected host:

```
You selected host: friendly_hostname23 - connecting...


This server is powered by Plesk.

Run the 'plesk login' command and log in by browsing either of the links received in the output.
Use the 'plesk' command to manage the server. Run 'plesk help' for more info.

root@friendly_hostname23:~# exit
logout
Connection to hostname23.host closed.
```

Once you close the session on the host, you will be prompted back to the list of groups, type the last number to exit:

```
Select a group of connections (number):
1) Group 1 Name
2) Group 5 Name
3) Group 2 Name
4) Group 3 Name
5) Group 4 Name
6) Exit
#? 6
Goodbye!
```