Default:

```
user@host:~# sudo df -h
Filesystem        Size  Used Avail Use% Mounted on
udev               32G     0   32G   0% /dev
tmpfs             6.3G  1.2M  6.3G   1% /run
/dev/md1           40G   11G   27G  30% /
tmpfs              32G     0   32G   0% /dev/shm
tmpfs             5.0M     0  5.0M   0% /run/lock
tmpfs              32G     0   32G   0% /sys/fs/cgroup
/dev/md0          279M  184M   76M  71% /boot
/dev/md2          875G  261G  570G  32% /data
tmpfs             6.3G     0  6.3G   0% /run/user/0
/dev/veeamimage1   40G   11G   27G  30% /tmp/veeam/snapmnt/{f940f86d-816d-4690-aea9-e4fc2ddc6a46}
/dev/veeamimage0  279M  184M   76M  71% /tmp/veeam/snapmnt/{f940f86d-816d-4690-aea9-e4fc2ddc6a46}/boot
/dev/veeamimage2  875G  261G  570G  32% /tmp/veeam/snapmnt/{f940f86d-816d-4690-aea9-e4fc2ddc6a46}/data
```

Script:

```
user@host:~# sudo ./calculate_used_space_with_exclusions.sh
Filesystem: /
  Total size of specified directories: 6G
  Original used space according to df -h: 10G
  Adjusted used space (after subtracting directories): 4G
Filesystem: /data
  Total size of specified directories: 208G
  Original used space according to df -h: 260G
  Adjusted used space (after subtracting directories): 52G
```

Edit:
```
declare -A dirs=(
    ["/data/automysqlbackup/"]="/data"
    ["/data/chroot/"]="/data"
    ["/etc/letsencrypt/archive/"]="/"
    ["/root/.composer/cache/"]="/"
    ["/root/.wp-cli/cache/"]="/"
    ["/var/cache/apt/"]="/"
    ["/var/lib/"]="/"
    ["/var/log/"]="/"
)
```
