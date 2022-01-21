cwd = pwd;
cleanup = onCleanup(@()cd(cwd));
cd(fileparts(mfilename('fullpath')));
install_and_setup
run_test
