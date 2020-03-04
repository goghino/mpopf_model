function mpopt = create_options(mpc, N, Ns, solver, start, voltage, balance)
%create_options Creates matpower options structure.
%
% mpopt = create_options(mpc, N, Ns, solver, start, voltage, balance)
%
% Outputs
%    mpopt: Matpower options structure
%
% Inputs
%   mpc     - Matpower case
%   N       - number of time periods (for MPOPF) 
%   Ns      - number of storage devices (for MPOPF)
%   solver  - Optimizaiton software used to solve the OPF
%   start   - Strategy for initializing OPF starting point
%   voltage - Voltage representation
%   balance - Type of nodal balance equation

    constants;
    mpopt = mpoption('verbose', 2);
    
    %% initialization mode
    %%%  1 = default starting point
    %%%  2 = starting point taken directly from mpc
    %%%  3 = AC power flow solution used as starting point
    mpopt = mpoption(mpopt, 'opf.start', start);
    
    % set options for the Newton's method used to solve PF as an initial guess
    mpopt = mpoption(mpopt, 'pf.alg', 'NR', 'pf.tol', 1e-8, 'pf.nr.max_it', 30);

    %% select OPF formulation
    mpopt = mpoption(mpopt, 'opf.v_cartesian', voltage, 'opf.current_balance', balance);

    %% Select and configure the solver    
    tolerance = 1e-4;
    max_iter = 500;
    mpopt = mpoption(mpopt, 'opf.violation', tolerance);

    if (solver == IPOPT)
        %for further options see ipopt.opt
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'IPOPT');
        mpopt.ipopt.opts = struct('linear_solver', 'pardiso', ...
           'max_iter', max_iter, 'tol', tolerance, ...
           'dual_inf_tol', tolerance, 'constr_viol_tol', tolerance, ...
           'compl_inf_tol', tolerance);
     elseif (solver == IPOPTHSL)
        %for further options see ipopt.opt
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'IPOPT');
        mpopt.ipopt.opts = struct('linear_solver', 'ma57', ...
            'max_iter', max_iter, 'tol', tolerance, ...
            'dual_inf_tol', tolerance, 'constr_viol_tol', tolerance, ...
            'compl_inf_tol', tolerance);
    elseif (solver == MIPS)
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'MIPS', 'mips.step_control', 0);
        mpopt.mips.max_it  = max_iter;
        mpopt.mips.feastol = tolerance;
        mpopt.mips.gradtol = tolerance;
        mpopt.mips.comptol = tolerance;
        mpopt.mips.costtol = tolerance;
    elseif (solver == MIPSsc)
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'MIPS', 'mips.step_control', 1);
        mpopt.mips.max_it  = max_iter;
        mpopt.mips.feastol = tolerance;
        mpopt.mips.gradtol = tolerance;
        mpopt.mips.comptol = tolerance;
        mpopt.mips.costtol = tolerance;
    elseif (solver == KNITRO)
        %for further options see knitro.opt
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'KNITRO');
        mpopt.knitro.maxit = max_iter;
        mpopt.knitro.tol_x = tolerance;
        mpopt.knitro.tol_f = tolerance;
        mpopt.knitro.opt=0;
        mpopt.knitro.opt_fname='knitro.opt';
    elseif (solver == FMINCON)
        mpopt = mpoption(mpopt, 'opf.ac.solver', 'FMINCON');
        mpopt.fmincon.max_it = max_iter;
        mpopt.fmincon.tol_x = tolerance;
        mpopt.fmincon.tol_f = tolerance;
    elseif (solver == BELTISTOSopf)
       %for further options see beltistos.opt
       mpopt = mpoption(mpopt, 'opf.ac.solver', 'IPOPT');
       mpopt.ipopt.opt=0;
       mpopt.ipopt.opts = struct('linear_solver', 'beltistos-opf', ...
           'max_iter', max_iter, 'tol', tolerance, ...
           'dual_inf_tol', tolerance, 'constr_viol_tol', tolerance, ...
           'compl_inf_tol', tolerance);
    elseif (solver == BELTISTOSmpopf)
       %for further options see beltistos.opt
       mpopt = mpoption(mpopt, 'opf.ac.solver', 'IPOPT');
       mpopt.ipopt.opt=0;
       mpopt.ipopt.opts = struct('linear_solver', 'beltistos-mpopf', ...
           'mem_saving_mode',        0, ...
           'number_of_timesteps',    N, ...
           'number_of_storages',     Ns, ...
           'number_of_buses',        size(mpc.bus,1), ...
           'number_of_generators',   size(mpc.gen,1)+2*Ns, ...
           'number_of_lines',        size(mpc.branch,1), ...
           'max_iter', max_iter, 'tol', tolerance, ...
           'dual_inf_tol', tolerance, 'constr_viol_tol', tolerance, ...
           'compl_inf_tol', tolerance);
     elseif (solver == BELTISTOSmem)
       %for further options see beltistos.opt
       mpopt = mpoption(mpopt, 'opf.ac.solver', 'IPOPT');
       mpopt.ipopt.opt=0;
       mpopt.ipopt.opts = struct('linear_solver', 'beltistos-mpopf', ...
           'mem_saving_mode',        1, ...
           'number_of_timesteps',    N, ...
           'number_of_storages',     Ns, ...
           'number_of_buses',        size(mpc.bus,1), ...
           'number_of_generators',   size(mpc.gen,1)+2*Ns, ...
           'number_of_lines',        size(mpc.branch,1), ...
           'max_iter', max_iter, 'tol', tolerance, ...
           'dual_inf_tol', tolerance, 'constr_viol_tol', tolerance, ...
           'compl_inf_tol', tolerance);       
    end
end