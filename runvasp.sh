#!/bin/bash
module load nvhpc-hpcx-cuda13/25.11
mpirun -np 1 /apps/tar/vasp_5090/vasp.6.4.2/bin/vasp_std
