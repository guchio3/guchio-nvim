# guchio-nvim
how to build
```
docker build -t nvim .
```

how to run
```
docker run --rm -it -u $(id -u):$(id -g) -e HOME=/root -v $HOME:$HOME --workdir=$(pwd) nvim
```

set alias
```
```
