# CLI-TOOLS

# Utilities

## s • Quickly list your .ssh/config connections by group

Type `s` instead of `ssh` to group, select and connect to your SSH hosts from `~/.ssh/config`.

Details for the `s` command in [s/README.md](s/README.md).

![demo](s/img/demo.gif)


# Installation

**Automated install**

```
curl -sSL https://raw.githubusercontent.com/germain-italic/cli-tools/master/installer.sh | bash
```

**Or Manual install**

```
git clone https://github.com/germain-italic/cli-tools.git ~/cli-tools
echo -e "source ~/cli-tools/tools.sh" >> ~/.bashrc
source ~/.bashrc
```

You may need to restart your shell if `source` didn't work.

# Uninstall

```
rm -rf ~/cli-tools
sed -i '/source ~\/cli-tools\/tools.sh/d' ~/.bashrc
```

Then restart your shell.

# Update

```
cd ~/cli-tools && git pull && source ~/.bashrc
```

# Todo

- [ ] Use [Gum](https://github.com/charmbracelet/gum)

# Synology Firewall CLI Tools

The `synology/firewall` directory is a **Git submodule** containing a collection of CLI scripts to manage firewalls on Synology NAS systems.

## Installation

After cloning `cli-tools`, you need to initialize the submodule:

```bash
./synology/firewall-install.sh
```

This will:

- Initialize the `synology/firewall` submodule
- Install a Git hook to auto-update the submodule after each `git pull`

## Update

To manually update the firewall tools:

```bash
./synology/firewall-update.sh
```

To remove the firewall tools completely:

```bash
./synology/firewall-remove.sh
```

> The `firewall` scripts are maintained in a separate repository:  
> https://github.com/germain-italic/synology-nas-cli-firewall-manager

## FAQ: Do I need to commit submodule updates?

If you are **just using** the `cli-tools` project:

- ✅ No, you do not need to commit anything.
- Running `./synology/firewall-update.sh` will update the scripts locally for your own use.

If you are a **contributor pushing changes**:

- ✅ Yes, you must commit the updated submodule reference:
  ```bash
  git commit -m "Update firewall submodule"
  git push
  ```

This ensures that everyone using the main repository sees the correct version of the `synology/firewall` scripts.