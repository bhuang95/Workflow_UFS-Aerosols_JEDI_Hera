import datetime as dt
import netCDF4 as nc
import os, argparse

'''
Command:
    python replace_aeroanl_restart.py -i JEDI -o NEW -m 0 -n 2 -v INVARS.nml
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Replace background aerosol file with JEDI aerosol analysis'
        )
    )


    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-v', '--variable',
        help="Input file containing the  variables",
        type=str, required=True)

    args = parser.parse_args()
    invarnml = args.variable

    inpre='input'
    outpre='output'

    with open(invarnml, 'r') as fd:
	    invars=fd.read().strip().split(',')
    print(invars)
	
    for j in range(1,7):
        tile=f'tile{j}'
        inname = f'{inpre}.{tile}'
        outname = f'{outpre}.{tile}'
        with nc.Dataset(outname,'a') as outfile:
            with nc.Dataset(inname,'r') as infile:
                for vname in invars:
                    print(vname)
                    indata = infile.variables[vname][:]
                    outfile.variables[vname][:] = indata[:]
