# Debian Plasma Mobile build system

Please start by downloading the sources you need. The first time downloading will take quite a long time depending on your internet connection.

`./packages.sh $package_list` e.g. "plasma-mobile"

Then continue by [creating a cowbuilder build environment](pbuilder/README.md).

After building your first package, the output will be in `repo-conf/incoming`.
You can import it into the binary repository as described [here](https://github.com/debian-pm-tools/apt-repo-conf/blob/master/README.md).
