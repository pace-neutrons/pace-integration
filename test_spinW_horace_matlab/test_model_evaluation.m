classdef test_model_evaluation < TestCase
    properties
        visual_inspection = false
    end
    %
    methods
        function obj=test_model_evaluation(varargin)
            if nargin == 0
                name = 'test_model_evaluation';
            else
                name = varargin{1};
            end
            obj = obj@TestCase(name);
            % enable visual inspection when investigating models manually
            %obj.visual_inspection = true;
        end
        %
        function test_evaluate_model(obj)
            clWarn = set_temporary_warning('off','sw_nb:WrongInput');
            sq = sw_model('squareAF',1,0);

            % We add magnetic form factor after the model is defined. Using the same
            % atom label and position as an existing atom in the model, the atom
            % properties will be updated, no new atom is created using the
            % spinw.addatom method. We will use the form factor of Ni2+ that has S=1.

            sq.addatom('label','atom_1','r',[0 0 0],'formfact','MNi2+','S',1)
            if obj.visual_inspection
                plot(sq)
                swplot.zoom(2)
            end

            %Spin wave
            %We need to define a grid in reciprocal space, here we use the (Qh, Qk, 0) square lattice plane by calling ndgrid() function.

            nQ = 201;
            nE = 501;
            Qhv = linspace(0,2,nQ);
            Qkv = linspace(0,2,nQ);
            Qlv = 0;
            [Qh, Qk, Ql] = ndgrid(Qhv,Qkv,Qlv);

            % Create a list of Q point, with dimensions of [3 nQ^2].
            Q = [Qh(:) Qk(:) Ql(:)]';

            % Spin wave spectrum
            % We calculates the spin wave spectrum at the list of Q points, bin the diagonal of the spin-spin correlation function (Sxx+Syy+Szz) in energy and convolute with a finite instrumental resolution.

            spec = sq.spinwave(Q);

            Ev = linspace(0,5,nE);
            spec = sw_egrid(spec,'component','Sxx+Syy+Szz','Evect',Ev);
            spec = sw_instrument(spec,'dE',0.1);

            %Creat the Q map
            %The calculated intensity map is stored in spec.swConv, we reshape it into a 3D matrix using Matlab commands.

            spec3D = reshape(spec.swConv,nE-1,nQ,nQ);

            %Plotting E=const cut
            % A constant energy cut takes the (Eidx,:,:) elements of the matrix and
            % plots it using the Matlab function imagesc(). We also integrate in energy
            % the same way Horace does by taking the average of the points and
            % rescaling with the energy bin size.

            Ecut = [3.5 4.0]; %meV
            Eidx = find(Ev>=Ecut(1) & Ev<=Ecut(2));
            cut1 = squeeze(sum(spec3D(Eidx,:,:),1))/numel(Eidx)/(Ev(2)-Ev(1));
            if obj.visual_inspection
                figure;
                imagesc(Qhv,Qkv,cut1);
                set(gca,'YDir','normal')
                xlabel('(H 0 0) (r.l.u.)')
                ylabel('(0 K 0) (r.l.u.)')
                title('Spin wave spectrum at E = 3 meV, square lattice Heisenberg AF')
                clim([0 3])
                colorbar
            end
            %Constant energy cut using Horace
            %We can do the same cut much easyer using Horace (http://horace.isis.rl.ac.uk). Assuming that Horace is installed and initialized we can do the same constant energy cut with just three steps. First we create an empty d3d object that defines the (h,k,0) plane with ranges in momentum and energy. Second we call Horace to fill up the empty d3d object with the simulated spin wave data and finally we plot a constant energy cut.

            Ebin   = [0,0.01,5];
            fwhm0  = 0.1;
            d3dobj = d3d(sq.abc,[1 0 0 0],[0,0.01,2],[0 1 0 0],[0,0.01,2],[0 0 0 1],Ebin);
            d3dobj = disp2sqw_eval(d3dobj,@sq.horace,{'component','Sxx+Syy+Szz'},fwhm0,'-all');
            w2 = cut(d3dobj,[],[],[3.5 4]);
            if obj.visual_inspection
                plot(w2 );
                colorslider('delete')
                title('')
                clim([0 3])
                colorbar
            end
            % TODO:
            % Resolution function in sw_instrument and resolution function
            % in sw.horace disp2sqw_eval are calculated differently,
            % so images look similar but actually different. This should
            % eventually be fixed.
            assertElementsAlmostEqual(w2.s,cut1,'absolute',0.6);
        end
    end
end