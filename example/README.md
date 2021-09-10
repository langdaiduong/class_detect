# tflite_example

## Install 

```
flutter packages get
```

## Run

```
flutter run
```

## Caveat

```recognizeImageBinary(image)``` (sample code for ```runModelOnBinary```) is slow on iOS when decoding image due to a [known issue](https://github.com/brendan-duncan/image/issues/55) with image package.
