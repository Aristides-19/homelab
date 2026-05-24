These are bind mounted with `mount --bind /etc/pve/lxc/[ID].conf [ID].conf`.
So, git will break it in `git pull` if these files are changed.
