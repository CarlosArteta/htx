# HTX: **H**igh-**T**hroughput e**X**plorer

HTX is a computer vision and machine learning pipeline for the exploration and visualization of high-throughput image assays.
This a full demo implementation of HTX in MATLAB.

## Dependencies
 
* [MatConvNet](http://www.vlfeat.org/matconvnet/)
* [vl_feat](http://www.vlfeat.org/)
* [t-SNE MATLAB library](https://lvdmaaten.github.io/tsne/code/tSNE_matlab.zip)

## Demo

A pretrained demo is provided using the [Broad Institute's dataset BBBC021v1](https://data.broadinstitute.org/bbbc/BBBC021/) ([Caie et al., Molecular Cancer Therapeutics, 2010](http://mct.aacrjournals.org/content/9/6/1913)), available from the Broad Bioimage Benchmark Collection ([Ljosa et al., Nature Methods, 2012](https://www.nature.com/nmeth/journal/v9/n7/full/nmeth.2083.html)).

To confirm that everything is setup correctly, follow these steps:
 
* Install and setup the dependencies.
* Download the demo data (shown below).
* Set the appropriate root folder in `ProcessData.m`.
* Run `ProcessData.m`.
 
## Basic demo: data visualization

The basic demo includes trained models and pre-computed visualizations. 
Downloading the raw TIF data is not required for trying most data exploration functionalities in HTX, as they can be used with only the normalized RGB images.

* [BBBC021v1 - RGB images & models](http://www.robots.ox.ac.uk/~vgg/data/BBBC021_xxuM_MCF7/BBBC021_xxuM_MCF7.zip)

## Full demo: model training and full functionalities

In order to try the training, as well as the feature highlighting functionality of the toolbox, the raw TIF data is required.

* [Broad Institute's dataset BBBC021v1](https://data.broadinstitute.org/bbbc/BBBC021/)

The MATLAB script `preprocess/BBBC021v1/arrangeIMDB_BBBC021v1.m` is provided to arrange the data in the format required by HTX.

Finally, a set of rough cell masks are provided for the BBBC021v1 dataset, which is used during training to discard empty frames.

* [BBBC021v1 - masks](http://www.robots.ox.ac.uk/~vgg/data/BBBC021_xxuM_MCF7/BBBC021_xxuM_MCF7_masks.zip)

## General usage information

The main script is `ProcessData.m`, which executes the configuration of the
experiment, and runs the training, image encoding and exploration GUI.
 
The configuration of the experiment is done in `dataConfig()`,
and it consists of setting the relevant paths (e.g. paths to raw data, models, etc.), and the different running parameters.
 
The image database (IMDB) is a MATLAB structure containing the necessary information about each of image stack in the dataset.
Per image stack, it consists of 9 fields:

| Field Name    | Example         | Description                                                                                                  |
| :------------ |:----------------| :------------------------------------------------------------------------------------------------------------|
| filename      | stack_ABCD.tif  | name of the image stack                                                                                      |
| folder        | plate_1         | parent folder                                                                                                |
| role          | control         | role of the well, e.g. treated or control                                                                    |
| treatment     | taxol-3uM       | name of the treatment in the well                                                                            |
| wellpos       | A01             | position of the well in its plate                                                                            |
| wellsite      | 2               | position of the FoV within the well                                                                          |
| plateID       | ABDC_2017       | identifier of the plate                                                                                      |
| class         | 100             | class index of the well for training, e.g. all wells which received the same treatment are of the same class |
| plateclass    | 1               | analogous to the well class, but for plates. Usually, different plates would the of different class          |


An example imdb can be found in demo folder `metadata/BBBC021_xxuM_MCF7_imdb.mat`.
This is also generated automatically by the data preparation script `arrangeIMDB_BBBC021v1.m`
 
The core training of the method is based on the class information provided in the IMDB.
That is, images from wells of the same class (i.e. receiving the same treatment) will be considered as *similar*,
and *dissimilar* otherwise. Likewise, plate class information is used to discourage the texture description network to learn plate-specific feature (i.e. batch effects).

## License

Copyright (C) 2016-2017 by Carlos Arteta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.



