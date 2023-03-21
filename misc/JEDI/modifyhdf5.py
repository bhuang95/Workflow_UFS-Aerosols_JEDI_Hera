import h5py
import numpy as np
file = h5py.File('aod_viirs_obs_2018041500_sf6_hdf5_test.nc4', 'r+')
file.attrs['date_time']=np.int32(2019061406)
file['MetaData']['dateTime'].attrs['units']='seconds since 2019-06-14T06:00:00Z'
#fil[]e.attrs.modify('date_time',"2019061406")
file.close()
