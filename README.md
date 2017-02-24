
Pd Offline is a simple libpd wrapper written in ruby to generate or process wave file with pure data patches. It is executed as fast as possible (depending on your processor), so you don't have to wait any audio playback. You don't need audio neither, so it could be used on headless (actually mic/speaker-less) environnement like remote server.

This project is based on libpd project (https://github.com/libpd/libpd).

Following instructions are based on linux (ubuntu) but could be adapted for Windows and OSX

# Setup

we need to install prerequists (ruby and bundler) :

```
sudo apt-get install ruby
gem install bundler
```

clone pd-offline repository and install dependencies : 

```
git clone https://github.com/mgsx-dev/pd-offline
cd pd-offline
bundle install
cd ..
```

Following steps on libpd project (https://github.com/libpd/libpd), we need to build libpd (here we build version 0.8.3) :

```
git clone https://github.com/libpd/libpd.git
cd libpd
git checkout 0.8.3
git submodule init
git submodule update
make EXTRA=true LOCALE=true
cd ..
```

Note that EXTRA option enable pd externals build and LOCALE option fix a bug on Linux (and maybe other platform) about
parsing float from pd patches (see https://github.com/libpd/libpd/issues/130).

Now we have to copy libpd binary in pd-offline project. Following command works on Linux, you have to adapt binary name for other plaftorms : **libpd.dylib** on OSX, **libpd.dll** on windows.

```
cp libpd/libs/libpd.so pd-offline/libpd.so
```

Setup is OK now.

# Update

To update libpd, update your local libpd clone, build again and copy native library to pd-offline as described
in setup section.

To update pd-offline, update your local libpd clone (fetch and pull) and install/update dependencies as follow :

```
cd pd-offline
bundle install
```

That's it.

# Tutorial

## Generate sound

We first try pd-generate. It will generates a wave file (sample.wav in example directory) from a pure data patch (generate.pd in example directory). In this example, we generate a stereo file at 44100 Hz with a duration of 1.5 seconds which is the duration of the envelop in the example patch. So we will get a nice well formed sample.

```
ruby pd-generate.rb example generate.pd example/sample.wav 2 44100 1.5
```

## Process sound

Now, let's test the processor. It will generate a new wave file (sample2.wav in example directory) from the previous one by applying some effects from a second patch (process.pd in example directory). In this example, we generate a new wave file with the same format and length as the previous one.

```
ruby pd-process.rb example process.pd example/sample.wav example/sample2.wav
``` 

## Where to go

Just have a look in examples pd patches, you will understand how it works. Fell free to modify them or create your own.

Notes : 
* It's recommanded for process script that input wave file channels match patch channels mapping (from adc~ to dac~).
* process script could handle any wave format : non pcm, non 16 bits, any sample rates, mono or more than 2 channels.
