/*!\file
  \Class for parallel simulation caculate, change state of SimBox.
  \author David(Xiao Zhang).
 
  This file contains functions that are used to handle enviroments and common function
  for box.
 */
#ifndef PARALLELSIM_H
#define PARALLELSIM_H 

#include "GPUSimBox.cuh"
#include "Utilities/Opls_Scan.h"
#include "Utilities/Config_Scan.h"
#include "Utilities/metroUtil.h"
#include "Utilities/Zmatrix_Scan.h"
#include "Utilities/State_Scan.h"

// boltzman constant in kcal mol-1 K-1
const double kBoltz = 0.00198717;

struct SimPointers
{
	SimBox *innerbox;
    Environment *envH, *envD;
    Atom *atomsH, *atomsD;
    Molecule *moleculesH, *moleculesD, *molTrans;
	int numA, numM, numEnergies, maxMolSize;
	int *nbrMolsH, *nbrMolsD, *molBatchH, *molBatchD;
	double *energiesH, *energiesD;
};

__global__ void checkMoleculeDistances(Molecule *molecules, int currentMol, int startIdx, int numM, Environment *enviro, int *inCutoff);
__global__ void calcInterAtomicEnergy(Molecule *molecules, int curentMol, Environment *enviro, double *energies, int numEnergies, int *molBatch, int maxMolSize);
__global__ void aggregateEnergies(double *energies, int numEnergies, int interval, int batchSize);
__device__ double calc_lj(Atom atom1, Atom atom2, double r2);
__device__ double calcCharge(double charge1, double charge2, double r);
__device__ double makePeriodic(double x, double box);
__device__ double calcBlending(double d1, double d2);
__device__ int getXFromIndex(int idx);
__device__ int getYFromIndex(int x, int idx);
		
class ParallelSim
{
    private:
        GPUSimBox *box;
		SimPointers *ptrs;
        int steps;
        float currentEnergy;
        float oldEnergy;
        int accepted;
        int rejected;

    public:
        ParallelSim(GPUSimBox *initbox,int initsteps); 	
        ~ParallelSim(); 	
        float getcurrentEnergy(){return currentEnergy;}; 	
        int getaccepted() {return accepted;};
        int getrejected() {return rejected;};
        GPUSimBox * getGPUSimBox() {return box;};
        GPUSimBox * getdevGPUSimBox() {return box;};
		void writeChangeToDevice(int changeIdx);
		double calcSystemEnergy();
		double calcMolecularEnergyContribution(int molIdx, int startIdx = 0);
		int createMolBatch(int curentMol, int startIdx);
		double calcBatchEnergy(int numMols, int molIdx);
		double getEnergyFromDevice();
		double makePeriodicH(double x, double box);
        void runParallel(int steps);
};
 	
#endif