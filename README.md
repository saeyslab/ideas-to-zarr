# Exporting ImageStream data from IDEAS

Upon acquisition, the Luminex ImageStream produces a raw imaging file (RIF). This is a proprietary file format that
contains images and meta data about the acquisition run. This file is opened in the IDEAS software (Windows only)
provided by Luminex to perform compensation. This produces a compensated image file (CIF), which contains the
compensated images and the masks computed by IDEAS. IDEAS can also be used to perform analyses on the data and the meta
data of these analyses are stored in the data analysis file (DAF).

Unfortunately, all of these file formats are proprietary and there is no way to programmatically load them, for example
in a Python script. For a previous version of IDEAS (version 6.2), there was a [reverse engineered Bioformats
loader](https://docs.openmicroscopy.org/bio-formats/6.6.0/formats/amnis-flowsight.html) that allowed for the extraction
of the images and masks from a CIF file, but this no longer works for IDEAS version 6.3.

Therefore, the only way to export images from IDEAS so they can be processed in custom scripts, is to use IDEAS’
built-in export function. This function exports a TIFF file per image and per channel. This is very inefficient as it is
typical for a run to contain data of 50,000 or more cells, which leads to 600,000 TIFF files if all 12 channels are
collected. Additionally, there is no command line interface for the IDEAS software so the (slow) exports need to happen
manual by point-and-click. This can get very tedious if dozens of experiments are performed regularly.

To remedy these problems, I implemented a workflow using [AutoHotKey](https://www.autohotkey.com/) and
[zarr](https://zarr.readthedocs.io/en/stable/). AutoHotKey is a scripting software that allows for the automation of
point-and-click procedures in software running on Windows. Essentially, you tell AutoHotKey in a script when and where
to click on the screen. You can then fire up the script by pressing a shortcut and let AutoHotKey do the clicking for
you.

## Installation

This guide assumes you have installed the Luminex IDEAS software. The AutoHotKey sections can only be executed on
Windows.

Install [AutoHotKey v1.1](https://www.autohotkey.com/).

Install the requirements in a Python environment of you choice with pip:
```bash
pip install -r requirements.txt
```
We recommend using [mambaforge](https://github.com/conda-forge/miniforge).

## Usage

Below we describe the steps to export images and populations from IDEAS and convert them to a format that can easily be
used in Python scripts. This is done using Python and AutoHotKey scripts. AutoHotKey scripts can be activated by
executing them from the Windows File Explorer.

### Using AutoHotKey to automate exporting images from IDEAS

The script [images_export_ideas.ahk](images_export_ideas.ahk) defines two AutoHotKey shortcuts:

- Right Alt + S: export images for the currently opened CIF file.
- Right Alt + U: opens a directory selector and exports the images for all CIF files in that directory.

To run the shortcuts, IDEAS needs to be opened and maximized. The opened CIF also needs to be maximized within IDEAS.

Note that this script is written for a specific data set I worked with. Depending on the populations defined in the
IDEAS analysis, lines 24 and 25 need to be adapted so that the right population is selected in IDEAS' export dialog.

### Storing the images in a zarr file

I use the [zarr](https://zarr.readthedocs.io/en/stable/) storage format to store the exported TIFF images in a more
efficient and easy-to-use format. [ideas_to_zarr.py] defines a command line interface to convert a directory of TIFF
images as exported by IDEAS to a zarr file.

The script is executed as follows:
```bash
python ideas_to_zarr.py --channel 1 --channel 6 --channel 7 /path/to/ideas/dir
```
Or using Docker:
```
docker build -t ideastozarr:latest .
docker run --rm -v /path/to/ideas/dir:/data ideastozarr:latest --channel 1 --channel 6 --channel 7
```

The `--channel/-c` options define which channels need to be stored in the zarr file. The channel indexes correspond to
the file names exported by IDEAS, which look like this: 123_Ch1.tiff. “123” in this name is the object number, which is
a unique identifier used by IDEAS. The command line interface extracts this object number and stores it in the zarr file
attributes.

After conversion an image can be read from the zarr file using the following code:

```python
import zarr

z = zarr.open(path, mode="r")

idx = 0
image = z[idx].reshape(z.attrs["shape"][idx])
object_number = z.attrs["object_number"][idx]
```

As you can see, the images need to be reshaped to their original shape when read from the zarr file. This is because we
use the zarr [VLenArray](https://numcodecs.readthedocs.io/en/stable/vlen.html#vlenarray) codec to store the images, wich
only handles 1D arrays. We need to use the VLenArray codec, since imaging flow cytometry images have varying X and/or Y
dimensions within one dataset and the zarr format is by default optimized for storing large arrays with uniform
dimensions, like 10,000 x 10,000 x 10,000. We are thus dealing with variable-length, or _ragged_ arrays, which need some
extra consideration. The downsides are that the reshaping adds a bit of overhead, and that the full multi-channel image
needs to be read from disk even if you only need a subset of the channels.

### Exporting defined populations from IDEAS

Cell populations can be defined in IDEAS through a manual gating procedure. Exporting these populations is not
straight-forward. It can most efficiently be achieved by exporting a single feature per population. This feature export
creates a TSV file (stored with a .txt extension...) that contains the object number of each object in the population in
the first column. The object number can than be linked to the images allowing you to assign each image to a population.
You could add a population identifier to the zarr attributes, for example.

```python
import zarr

z = zarr.open(path, mode="r")

idx = 0
image = z[idx].reshape(z.attrs["shape"][idx])
object_number = z.attrs["object_number"][idx]
population = z.attrs["population"][idx]
```

The script [features_export_ideas.ahk](features_export_ideas.ahk) defines two AutoHotKey shortcuts:

- Right Alt + O: export populations for the currently opened CIF file.
- Right Alt + F: opens a directory selector and exports the features for all CIF files.

To run the shortcuts, IDEAS needs to be opened and maximized. The opened CIF also needs to be maximized within IDEAS.
