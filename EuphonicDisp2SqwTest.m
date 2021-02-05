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
            ws = read_sqw('quartz/cut1d.sqw');

            % Set up simulation
            scale_factor = 1e12;
            effective_fwhm = 1;
            fc = euphonic.ForceConstants.from_castep('quartz/quartz.castep_bin');
            euobj = euphonic.CoherentCrystal( ...
                fc, 'debye_waller_grid', [6 6 6], 'temperature', 100, ...
                'negative_e', true, 'asr', true, 'chunk', 1000, 'use_c', true, ...
                'eta_scale', 0.75);

            % Run simulation
            wsim = disp2sqw_eval(ws, @euobj.horace_disp, {scale_factor}, effective_fwhm);
            
            expected_wsim = read_sqw('quartz/expected_cut1d_disp2sqw_eval.sqw');

            testCase.verifyTrue( ...
                all(ismembertol(wsim.data.s, ...
                                expected_wsim.data.s, ...
                                1e-5*mean(expected_wsim.data.s)), 'all'));
        end

        function testQuartzCoherentCrystalDisp2sqwTobyfit(testCase)
            ws = read_sqw('quartz/cut1d.sqw');
            
            % Set up simulation
            intrinsic_fwhm = 0.1;
            scale_factor = 1e12;
            fc = euphonic.ForceConstants.from_castep('quartz/quartz.castep_bin');
            euobj = euphonic.CoherentCrystal( ...
                fc, 'debye_waller_grid', [6 6 6], 'temperature', 100, ...
                'negative_e', true, 'asr', true, 'chunk', 10000, 'use_c', true, ...
                'eta_scale', 0.75);

            % Run simulation with resolution convolution
            is_crystal = true; xgeom = [0,0,1]; ygeom = [0,1,0]; shape = 'cuboid'; shape_pars = [0.01,0.05,0.01];
            ws = set_sample(ws, IX_sample(is_crystal, xgeom, ygeom, shape, shape_pars));
            ei = 40; freq = 400; chopper = 'g';
            ws = set_instrument(ws, merlin_instrument(ei, freq, chopper));
            kk = tobyfit(ws);
            kk = kk.set_fun(@disp2sqw, {@euobj.horace_disp, {scale_factor}, [intrinsic_fwhm]});
            wsim = kk.simulate('fore');

            expected_wsim = read_sqw('quartz/expected_cut1d_disp2sqw_tobyfit.sqw');

            % Tobyfit results are non-deterministic and have high errors
            % when running such a quick test case, allow generous relative
            % errors
            rel_err = abs(wsim.data.s - expected_wsim.data.s)/expected_wsim.data.s;
            testCase.verifyLessThan(rel_err, 0.5);

        end
    end
end
