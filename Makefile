all: build-input build-tides build-output build-utils

build-input:
	cd input && gfortran -ffixed-line-length-none lambertInterpRamp.f -o lambertInterpRamp.x
	cd input && gfortran -ffixed-line-length-none awip_lambert_interp.F -o awip_lambert_interp.x

build-tides:
	cd tides && gfortran -ffixed-line-length-none tide_fac.f -o tide_fac.x
	cd tides && gfortran -ffixed-line-length-none FES952_interp.f -o FES952_interp.x
	cd tides && gfortran -ffixed-line-length-none ec2001v2d_tide_interp.f -o ec2001v2d_tide_interp.x
	cd tides && gfortran -ffixed-line-length-none tides_ec2001.f -o tides_ec2001.x

build-output:
	 #cd output/PartTrack/src && gfortran -ffixed-line-length-none drog2dsp_deepwater.f
	 cd output/PartTrack/src && gfortran -ffixed-line-length-none convert_numbers.f -o convert_numbers.x
	 #cd output && gfortran -ffixed-line-length-none wind.F
	 cd output/POSTPROC_KMZGIS/RenciGETools-1.0/src && gfortran -ffixed-line-length-none splitFort63.f -o splitFort63.x
	 #cd output && gfortran -ffixed-line-length-none aswip_1.0.3.F
	 #cd output/TRACKING_FILES && gfortran -ffixed-line-length-none drog2dsp_deepwater_node.f
	 #cd output/TRACKING_FILES && gfortran -ffixed-line-length-none drog2dsp_deepwater.f
	 cd output/TRACKING_FILES && gfortran -ffixed-line-length-none convert_numbers.f -o convert_numbers.x
	 #cd output && gfortran -ffixed-line-length-none vortex.F

build-utils:
	cd util/nodalattr && gfortran -ffixed-line-length-none surface_roughness_calc.f -o surface_roughness_calc.x
	cd util/nodalattr && gfortran -ffixed-line-length-none surface_canopy.f -o surface_canopy.x
	cd util/nodalattr && gfortran -ffixed-line-length-none inflate.F -o inflate.x
	cd util/levee_tools_etc && gfortran -ffixed-line-length-none interp_13.f -o interp_13.x
	cd util/levee_tools_etc && gfortran -ffixed-line-length-none EXTRACT_BARLANHT.f -o EXTRACT_BARLANHT.x
	#cd util/levee_tools_etc && gfortran -ffixed-line-length-none GRIDSTUFF.f
	cd util/levee_tools_etc && gfortran -ffixed-line-length-none INSERT_WEIRHEIGHTS.f -o INSERT_WEIRHEIGHTS.x
	#cd util/levee_tools_etc && gfortran -ffixed-line-length-none CHKWEIRS.f
	#cd util/levee_tools_etc && gfortran -ffixed-line-length-none STATIONS2KML.f
	#cd util/levee_tools_etc && gfortran -ffixed-line-length-none INSERT_GRID.f
	cd util/levee_tools_etc && gfortran -ffixed-line-length-none indx_interp.f -o indx_interp.x
	cd util/levee_tools_etc && gfortran -ffixed-line-length-none UPDATE13.f -o UPDATE13.x

clean:
	find . -name "*.x" -exec rm -v {} \;
	find . -name a.out -exec rm -v {} \;
