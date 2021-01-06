#!/bin/bash

# Get dependencies
pip install euphonic
git clone https://github.com/mducle/horace-euphonic-interface.git
cd horace-euphonic-interface && git checkout eb2f297 && cd ..

matlab -batch "addpath('horace-euphonic-interface'); run_euphonic_integration"
