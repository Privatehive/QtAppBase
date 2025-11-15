# Helper

## Create icons

The different target platforms require different icon formats. Use the Icon_template.svg to design your icon (in
Inkscape) and then generate all icon formats from it. Be sure to fill the predefined layers (foreground,
foreground_monochrome, background):

* foreground: contains the colored icon
* foreground_monochrome: contains the black & white icon
* background: contains the background that is shown behind the icon

> [!IMPORTANT]
> Don't change the order of the layers or add any new layers

Then build and run the Dockerfile like so (within the helper directory):

`$ docker run --rm -v $(pwd):/home $(docker build -q .) input_file.svg out_name`

and provide the params:

* input_file.svg: The source icon svg file containing the three layers (made from Icon_template.svg)
* out_name: The output name of each generated icon file (without file extension)

You will find the different icon formats in the icons_out folder.
