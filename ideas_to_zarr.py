import zarr
import tifffile
from pathlib import Path
import click
import numcodecs
import re
from tqdm import tqdm
import sys
import zarr.storage
import os


def main(
    path,
    channels
):

    sys.stderr = open('stderr.out', 'w')

    path = Path(path)

    tiff_paths = []
    for tiff_path in path.glob("*Ch1.*"):
        paths = [
            re.sub("Ch1", f"Ch{c}", str(tiff_path))
            for c in channels
        ]
        if all([os.path.exists(p) for p in paths]):
            tiff_paths.append(paths)

    zarr_length = len(tiff_paths)

    store = zarr.storage.DirectoryStore(str(path.with_suffix(".zarr")))
    z = zarr.open(
        store=store,
        shape=(zarr_length,),
        mode="w",
        chunks=(100,),
        dtype=object,
        object_codec=numcodecs.VLenArray('u2')
    )

    object_number = []
    shape = []

    for i, paths in enumerate(tqdm(tiff_paths, file=sys.stdout)):
        pixels = tifffile.imread(paths)
        z[i] = pixels.ravel()
        object_number.append(
            int(re.search("^([0-9]+)_.*$", os.path.basename(paths[0])).groups()[0]))
        shape.append(pixels.shape)

    z.attrs["object_number"] = object_number
    z.attrs["shape"] = shape
    print(z.info)
    print(z)


@click.command()
@click.argument("path", type=click.Path(exists=True, file_okay=False), default="/data")
@click.option("--channels", "-c", type=str, required=True)
def cmd(**kwargs):
    kwargs["channels"] = kwargs["channels"].split(",")
    main(**kwargs)


if __name__ == "__main__":
    cmd()
