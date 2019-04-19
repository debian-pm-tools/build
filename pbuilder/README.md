# Set up cowbuilder

Create the basepaths for the architectures you need:
```
sudo mkdir /var/cache/pbuilder/testing-$ARCH /var/cache/pbuilder/testing-$ARCH/aptcache -p
```

Then create the build environment using the custom pbuilderrc:
```
sudo ARCH=armhf cowbuilder create --configfile pbuilderrc
```

You can now build a package in the newly created environment:
```
sudo ARCH=armhf cowbuilder build --configfile pbuilderrc ../packages/package_0.1-1.dsc
```
