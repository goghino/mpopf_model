This demo is intended to run the OPF and MPOPF problems and requires
the following dependencies:

MATPOWER Version 7.0, 19-Jun-2019. MATPOWER is a package of Matlab
M-files for solving power flow and optimal power flow problems. It is
intended as a simulation tool for researchers and educators that is easy
to use and modify. For more information visit https://matpower.org

BELTISTOS, suite of high-performance OPF algorithms including extremely
scalable and low memory multiperiod OPF solver. For more information visit
http://www.beltistos.com

PARDISO Vers. 6.0, Runtime Modules of Parallel Sparse Linear Solver.
Copyright Universita della Svizzera Italiana 2000-2018. All Rights Reserved.
For more information visit https://www.pardiso-project.org

INSTALL:
========

Obtain the framework at http://www.beltistos.com. You will also need to
obtain the licence from the same website. The licence should
be located in `$(HOME)/pardiso.lic` file.


RUN:
=======

Set the parameters related to the problem specification and solver in the
main file `main.m`. Execute the file to run the simulation.

#### Problem configuration:
Specify the number of time periods (`Nperiod`) and storage devices (`Nstorage`).
If `Nperiod=1` a standard OPF problem is run. For `Nperiod>1` the MPOPF problem with
Nstorage devices is run. The power grid is selected using the variable OPFcase.
The OPF problem formulation is specified via OPFvoltage and OPFbalance variables.
The initial point is configured using OPFstart and the solver is selected via
OPFsolver. The available options for all parameters can be found in constants.m.

#### Examples:
In order to run the MPOPF problem with 24 time periods and 10 storage devices
using the IEEE 118 bus case, considering the polar-power OPF formulation using
BELTISTOS structure exploiting solver (note that only the default polar-power
combination is supported by BELTISTOS at the moment) and the initial point specified
in the case file, use the following options:
```
Nperiod = 24;
Nstorage = 10;
OPFcase = case118;
OPFvoltage = POLAR;
OPFbalance = POWER;
OPFstart = MPC;
OPFsolver = BELTISTOS;
```

In order to run the OPF problem using Pegase 1k bus case, considering the
polar-power OPF formulation using the standard BELTISTOS solver and the
initial point specified in the case file, use the following options:
```
Nperiod = 1;
OPFcase = case1354pegase;
OPFvoltage = POLAR;
OPFbalance = POWER;
OPFstart = MPC;
OPFsolver = BELTISTOSopf;
```
