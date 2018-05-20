# Set up cowbuilder

Create the basepaths for the architectures you need:
```
sudo mkdir /var/cache/pbuilder/testing-$ARCH
```

Then create the build environment using the custom pbuilderrc:
```
sudo ARCHITECTURE=armhf cowbuilder create --basepath /var/cache/pbuilder/testing-$ARCH/base.cow --configfile pbuilderrc --architecture $ARCH
```
