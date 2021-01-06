horace_on;

% Read in a Horace cut (in real workflow would make a cut from larger file).
ws = read_sqw('quartz/cut1d.sqw')

% Set up Euphonic
if ~ispc
    py.sys.setdlopenflags(int32(10))  % Needed on Linux due to linker issues
end
fc = euphonic.force_constants.from_castep('quartz/quartz.castep_bin')
euobj = euphonic.coherent_sqw(fc, 'debye_waller_grid', [6 6 6], 'temperature', 100, ...
                              'negative_e', true, 'asr', true, 'chunk', 10000, 'use_c', true)

% Some simulation parameters
scale_factor = 1e12;
effective_fwhm = 1;
intrinsic_fwhm = 0.1;

% Run simulation
wsim = disp2sqw_eval(ws, @euobj.horace_disp, {scale_factor}, effective_fwhm);

% Run simulation with resolution convolution
is_crystal = true; xgeom = [0,0,1]; ygeom = [0,1,0]; shape = 'cuboid'; shape_pars = [0.01,0.05,0.01];
ws = set_sample(ws, IX_sample(is_crystal, xgeom, ygeom, shape, shape_pars));
ei = 40; freq = 400; chopper = 'g';
ws = set_instrument(ws, merlin_instrument(ei, freq, chopper));
kk = tobyfit(ws);
kk = kk.set_fun(@disp2sqw, {@euobj.horace_disp, {scale_factor}, [intrinsic_fwhm]});
wsim_mf = kk.simulate('fore');

% Plots the data
hf = plot(ws); pl(wsim); acolor red; pl(wsim_mf);

% Other functionality of Euphonic (not needed for integration)
phm = fc.calculate_qpoint_phonon_modes(euphonic.mp_grid([6 6 6]))
dos = phm.calculate_dos(linspace(0, 100, 200) * euphonic.ureg('meV'))
xd = dos.x_data.magnitude;
figure; plot((xd(1:end-1)+xd(2:end))/2, dos.y_data.magnitude, '-');

waitfor(hf);
