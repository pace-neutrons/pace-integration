%% Runs the actual test
proj = line_proj([1, 0, 0], [0, 1, 0], 'type', 'rrr');
sqw_file = fullfile(fileparts(mfilename('fullpath')), 'pcsmo_cut1.sqw');
w1 = cut_sqw(sqw_file, proj, [-1, 0.05, 1], [-1, 0.05, 1], [-10, 10], [10, 20]);
w1 = mask_random_fraction_pixels(w1, 0.1);

Jvec = [-11.39, 1.5, -1.35, 1.5, 0.88, 0.074];
Jv = mat2cell(Jvec,1,ones(1,6)); [J1,J2,J3,J4,J5,J6] = Jv{:};
swo = pcsmo_model(J1, J2, J3, J4, J5, J6);

cpars = {'mat', {'JF1', 'JA', 'JF2', 'JF3', 'Jperp', 'D(3,3)'}, ...
    'hermit', false, 'useFast', false, 'formfact', true, ...
    'resfun', 'gauss', 'coordtrans', diag([2 2 1 1]), ...
    'optmem', 100};

frac = 1e-6;
cpars_brille = {'use_brille', true, 'node_volume_fraction', frac, ...
    'use_vectors', false, 'Qtrans', diag(1./[4 4 1])};

%w1 = mask_random_fraction_pixels(w1, 0.1);
rng(12345, 'twister')
kk = multifit_sqw(w1);
kk = kk.set_fun(@swo.horace_sqw, {[J1 J2 J3 J4 J5 J6 0.1] cpars{:}});
tic
wsim = kk.simulate();
tsim = toc;
fprintf('Time to run SpinW normally = %0.2f s\n', tsim)

rng(12345, 'twister')
kk = multifit_sqw(w1);
kk = kk.set_fun(@swo.horace_sqw, {[J1 J2 J3 J4 J5 J6 0.1] cpars{:} cpars_brille{:}});
tic
wbrille = kk.simulate();
tbrille = toc;
fprintf('Time to run SpinW with Brille = %0.2f s\n', tbrille)
fprintf('Speed up factor = %0.4f\n', tsim/tbrille)

% Calculate fractional mean average error
err = sum(sum(abs(wsim.data.s - wbrille.data.s))) / numel(wsim.data.s) / mean(wsim.data.s(:));
fprintf('Relative per bin error in calculation = %0.2f %%\n', err*100)
% 0.3169 % frac=1e-6
% 0.5135 % frac=1e-5
%err = sum(abs(wsim.data.pix.signal - wbrille.data.pix.signal)) / wsim.data.num_pixels / mean(wsim.data.pix.signal)
% 0.8397 % frac=1e-6
% 1.4911 % frac=1e-5

if (err > 0.5) % Fail if error larger than 50% - (was 32% when written)
    % If the error goes up, sign that some changes to one of
    % Brille / SpinW / Horace has gone wrong, and should be flagged.
    disp('FAILURE: relative error too large');
    quit(1)
end
disp('SUCCESS');
