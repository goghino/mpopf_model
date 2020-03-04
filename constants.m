%OPFsolver
MIPS=1;
MIPSsc=2;
FMINCON=3;
IPOPT=4;
KNITRO=5;
BELTISTOSopf=6;
MIPSscPardiso=7;
IPOPTHSL=8;
BELTISTOSmpopf=9;
BELTISTOSmem=10;

%OPFstart
FLAT = 1;
MPC = 2;
PF = 3;

%OPFvoltage
POLAR = 0;
CARTESIAN = 1;

%OPFbalance
POWER = 0;
CURRENT = 1;

%Other runtime configurations
setenv('OMP_NUM_THREADS','1');
define_constants;