# MTR-KML-Converter
Convert .kml files for MTRs into ForeFlight-friendly versions.

If you don't have access to the NGA's aviation data portal, this
will not be terribly useful to you, but for military pilots flying
with iPads, GPS pucks and ForeFlight, this tool can be used to convert the
NGA's ugly, big DAFIF MTR .kml files into nice small ones with 
pretty icons.

It will split big NGA .kml file containing all routes of a given
type into one .kml file per route, so you
can just add the .kml files for the routes you need into ForeFlight.

Dependencies
------------

You'll need the DMD D compiler from <dlang.org>. It should build fine
on either Windows or Linux, but I tested it on Linux.

Build Instructions
------------------

    > rdmd --build-only parsemtrkml.d

Usage
-----

A script, `runparser.sh` is included. Place the input .kml files, the
the `parsemtrkml` executable and the script in the same folder, and run:

    > chmod +x runparser.sh
    > runparser.sh

If you want to use the tool on individual file sets, try:

    > parsemtrkml -t <TYPE> -i <INPUT FILES> -o <OUTPUT FOLDER>
    
For example:

    > parsemtrkml -t SR -i mtrsrs.kml,mtrsr_l.kml,mtrov_sr_l.kml -o output

Thanks
------
This includes Adam D. Ruppe's <github.com/adamdruppe> arsd.dom and 
arsd.characterencodings libraries
(Boost License), thank you Adam for the great work!
