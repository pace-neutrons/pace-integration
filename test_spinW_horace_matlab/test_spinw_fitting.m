classdef test_spinw_fitting < TestCase
    properties
        w_fe % workspace with 1D iron dataset
    end
    %
    methods
        function obj=test_spinw_fitting(varargin)
            if nargin == 0
                name = 'test_spinw_fitting';
            else
                name = varargin{1};
            end
            obj = obj@TestCase(name);
            this_dir = fileparts(mfilename("fullpath"));            
            obj.w_fe = read_sqw(fullfile(this_dir, 'fe_cut.sqw'));            
        end
        %
        function test_fit(obj)
            % Reads in the cut data


            % Set up SpinW model
            a = 2.87;
            fe = spinw();
            fe.genlattice('lat_const', [a, a, a], 'angled', [90, 90, 90], 'sym', 'I m -3 m')
            fe.addatom('label', 'MFe3', 'r', [0, 0, 0], 'S', 5/2, 'color', 'gold')
            fe.gencoupling()
            fe.addmatrix('label', 'J1', 'value', 1, 'color', 'gray')
            fe.addmatrix('label', 'D', 'value', diag([0, 0, -1]), 'color', 'green')
            fe.addcoupling('mat', 'J1', 'bond', 1)
            fe.addaniso('D')
            fe.genmagstr('mode', 'direct', 'S', [0., 0., 1.; 0., 0., 1.]');

            % Set up multi-fit
            % Starting parameters for fit
            J = 35;     % Exchange interaction in meV
            D = 0;      % Single-ion anisotropy in meV
            gam = 30;   % Intrinsic linewidth in meV (inversely proportional to excitation lifetime)
            temp = 10;  % Sample measurement temperature in Kelvin
            amp = 300;  % Magnitude of the intensity of the excitation (arbitrary units)

            cpars = {'mat', {'J1', 'D(3,3)'}, 'hermit', false, 'optmem', 1, ...
                'useFast', true, 'resfun', 'sho', 'formfact', true};

            kk = multifit_sqw(obj.w_fe);
            kk = kk.set_fun (@fe.horace_sqw, {[J, D, gam, temp, amp], cpars{:}});
            kk = kk.set_free ([1, 0, 1, 0, 1]);
            kk = kk.set_bfun (@linear_bg, [0.1, 0]);
            kk = kk.set_bfree ([1, 0]);
            kk = kk.set_options ('list', 2);

            tic();
            wsim = kk.simulate();
            t_spinw_single = toc();
            fprintf('Time to evaluate a single iteration: %s s\n', t_spinw_single);

            tic();
            [wfit, fitpars] = kk.fit();
            t_spinw_fit = toc();
            fprintf('Time to run fit: %s s\n', t_spinw_fit);

            assertEqualToTol(fitpars.p,[15.2440 0 65.9076 10 135.4074],'tol',[1.e-3,1.e-3]);
        end
    end
end