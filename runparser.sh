#!/bin/bash -x
mkdir output
./parsemtrkml -t IR -i mtrirs.kml,mtrir_l.kml,mtrov_ir_l.kml -o output
./parsemtrkml -t SR -i mtrsrs.kml,mtrsr_l.kml,mtrov_sr_l.kml -o output
./parsemtrkml -t VR -i mtrvrs.kml,mtrvr_l.kml,mtrov_vr_l.kml -o output
