# testing locally in whalebuilder

You can build packages locally using the same docker images that the GitLab ci uses.

First create a whalebuilder compatible image with our image as base:
```
whalebuilder create --eat-my-data whalebuilder-debian-pm -d jbbgameich/build -r latest-amd64
```
Now you can build packages in your newly created environment:
```
whalebuilder build whalebuilder-debian-pm ../kaidan_0.3.2+git20181020-1.dsc
```

