
# Benchmark your Pd patch

## Run benchmark from your host system

From your pd-offline clone folder (eg. /home/user/git/pd-offline), just type :

```
ruby -I lib benchmark/pd-benchmark.rb
```

This will run benchmark for the default patch folder 'benchmark/patches' which contains some examples. To benchmark patches from a different folder just add your path as first argument of the script :

```
ruby -I lib benchmark/pd-benchmark.rb path/to/your/patches/folder
```

## With docker

Docker let you run processes in an isolated container and let you configure a variety of options like limiting CPU usage.

First you need to have docker 1.13+ installed on your system.

Then you have to build the benchmark docker image. This has to be done once until docker build file change (after pulling some changes) :

```
docker build -f benchmark/Dockerfile -t pd-offline-benchmark .
```

Finally run benchmark :

```
docker run -it --rm --name pd-offline-benchmark \
	-v "$PWD":/usr/src/myapp -w /usr/src/myapp \
	-v "$PWD/benchmark/patches":/patches \
	--cpus=".5" \
	pd-offline-benchmark ruby -I lib benchmark/pd-benchmark.rb /patches
```

Note that `--cpus=".5"` let you limit CPU usage. 0.5 mean up to 50% of 1 CPU. Minimum is 0.01 (1% of 1 CPU).
You can set more than one CPU (eg. 1.5 means 1 CPU and a half) but since we're running a single process we won't see any difference. You can remove completely this option to take all available CPU resources.
Obviously this option will significally changes benchmark results, because it's "simulate" a cheaper machine.

To run benchmark on patch from another directory (your patch directeory), just change docker volume `"$PWD/benchmark/patches":/patches` to `"/absolute/path/to/my/patch/folder":/patches`.

# Interpret the result

Benchmarking is very tricky and results have to be take with care. Benchmark execution context is crutial then results could be slightly different accross different context (OS, Architecture, Installation, Other process running ...). So instead of saying "My patch eats 1% of CPU" you should say "My patch seams to eat about twice CPU as another patch I made".

This benchmark procedure run each patch individually from specified folder. It will generate 100 seconds of signal
at a sample rate of 48000 Hz. Displayed "user" time is the metric you're looking for and express how much time it takes to generate 100 seconds of your patch. For instance, if your patch takes 3.5 seconds of user time, you can say "my patch seams to eat about 3.5% of CPU on my machine". If you're using docker CPU limits at 0.5, you can say "my patch seams to eat about 3.5% of CPU on a machine half powerfull than mine".
