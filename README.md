# Pycopy firmware builder for ESP32

This project provides a Dockerfile to automate the building process of the **ESP32** port of [Pycopy](https://github.com/pfalcon/pycopy). It should also work for building the original [MicroPython](https://github.com/micropython/micropython) or other branches of the project.

Versions tested so far (let me know to update this list!):

| Branch | Version | Works    | Comments                             |
|--------|---------|:--------:|--------------------------------------|
| Pycopy | 3.1.5   | &#10003; |                                      |
| Pycopy | 3.2.3   | &#10003; |                                      |
| Pycopy | 3.3.0   | &#10003; |                                      |
| Pycopy | 3.3.2   | &#10003; |                                      |

## Building the firmware

Download the repository and build the Docker image:

```shell
$ docker build -t pycopy-builder .
```

This will take a while, but the image should be built successfully. After that, extract the firmware using

```shell
$ ./get_firmware.sh pycopy-builder
```

and you should get a `firmware.bin` file in the directory.

### Double precision floats

MicroPython comes with simple precision floats by default. If you need a little more, you can enable double precision floats when building the Docker image like

```shell
$ docker build -t pycopy-builder --build-arg DOUBLE_PRECISION_FLOATS=true .
```

### Build arguments

There are a few arguments you can use to tweak your build.

| **Argument name**       | **Default value**                 | **Description**                                |
|-------------------------|-----------------------------------|------------------------------------------------|
| REPO                    | https://github.com/pfalcon/pycopy | MicroPython repository to be built.            |
| BRANCH                  | v3.3.2                            | Branch name of the repository.                 |
| DOUBLE_PRECISION_FLOATS | false                             | If `true`, enables double precision floats.    |
| MODULES_PATH            |                                   | Module file or modules directory to be frozen. |

Example:

```shell
$ docker build -t pycopy-builder \
    --build-arg REPO=https://github.com/pfalcon/pycopy \
    --build-arg BRANCH=v3.3.2 \
    --build-arg DOUBLE_PRECISION_FLOATS=true \
    --build-arg MODULES_PATH=your_modules_folder .
```

## References

- https://www.microdev.it/wp/en/2018/08/08/esp32-micropython-compiling-for-esp32/
- https://gist.github.com/tdamsma/b49359448924d7aa816d50be2170a610
