classdef EuphonicDisp2SqwTest < matlab.mock.TestCase

    methods(TestClassSetup)
        function setLinuxLibFlags(testCase)
            if ~ispc
                py.sys.setdlopenflags(int32(10));  % Needed on Linux due to linker issues
            end
        end
    end

    methods(Test)
        function testQuartzCoherentCrystalDisp2sqweval(testCase)
            disp('Running testQuartzCoherentCrystalDisp2sqweval...');
            disp('Reading sqw...');
            ws = read_sqw('quartz/cut1d.sqw')

            % Set up simulation
            disp('Setting up CoherentCrystal...');
            scale_factor = 2e2;
            effective_fwhm = 1;
            fc = euphonic.ForceConstants.from_castep('quartz/quartz.castep_bin');
            euobj = euphonic.CoherentCrystal( ...
                fc, 'debye_waller_grid', [6 6 6], 'temperature', 100, ...
                'negative_e', true, 'asr', true, 'chunk', 1000, 'use_c', true, ...
                'dipole_parameter', 0.75);

            % Run simulation
            disp('Running disp2sqw_eval');
            wsim = disp2sqw_eval(ws, @euobj.horace_disp, {scale_factor}, effective_fwhm);

            disp('Reading expected sqw...');
            expected_wsim = read_sqw('quartz/expected_cut1d_disp2sqw_eval.sqw');

            disp('Testing result...');
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.constraints.RelativeTolerance
            bounds = AbsoluteTolerance(1e-5*mean(expected_wsim.data.s)) | RelativeTolerance(1e-5);
            testCase.verifyThat(wsim.data.s, ...
                IsEqualTo(expected_wsim.data.s, 'within', bounds));

        end

        function testQuartzCoherentCrystalDisp2sqwTobyfit(testCase)
            FIXED_SEED = 101;
            [rng_state, old_rng_state] = seed_rng(FIXED_SEED);
            clean_up = onCleanup(@() rng(old_rng_state));
            fprintf('RNG seed: %i\n', rng_state.Seed)

            disp('Running testQuartzCoherentCrystalDisp2sqwTobyfit...');
            disp('Reading sqw...');
            ws = read_sqw('quartz/cut1d.sqw');
            
            % Set up simulation
            disp('Setting up CoherentCrystal...');
            intrinsic_fwhm = 0.1;
            scale_factor = 2e2;
            fc = euphonic.ForceConstants.from_castep('quartz/quartz.castep_bin');
            euobj = euphonic.CoherentCrystal( ...
                fc, 'debye_waller_grid', [6 6 6], 'temperature', 100, ...
                'negative_e', true, 'asr', true, 'chunk', 10000, 'use_c', true, ...
                'dipole_parameter', 0.75);

            % Run simulation with resolution convolution
            disp('Running disp2sqw_eval with resolution convolution');
            is_crystal = true; xgeom = [0,0,1]; ygeom = [0,1,0]; shape = 'cuboid'; shape_pars = [0.01,0.05,0.01];
            sample = IX_sample(is_crystal, xgeom, ygeom, shape, shape_pars);
            sample.alatt = [4.9, 4.9, 5.4];
            sample.angdeg = [90, 90, 120];
            ws = set_sample(ws, sample);
            ei = 40; freq = 400; chopper = 'g';
            ws = set_instrument(ws, merlin_instrument(ei, freq, chopper));
            kk = tobyfit(ws);
            kk = kk.set_fun(@disp2sqw, {@euobj.horace_disp, {scale_factor}, [intrinsic_fwhm]});
            wsim = kk.simulate('fore');

            disp('Reading expected sqw...');
            expected_wsim = read_sqw('quartz/expected_cut1d_disp2sqw_tobyfit.sqw');

            disp('Testing result...');
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.constraints.RelativeTolerance
            bounds = AbsoluteTolerance(1e-10*mean(expected_wsim.data.s)) | RelativeTolerance(5e-5);
            testCase.verifyThat(wsim.data.s, ...
                IsEqualTo(expected_wsim.data.s, 'within', bounds));
        end
    end
end
