# Create a list of the example files in the EnergyPlus directory for squish testing

file( GLOB_RECURSE xmpl_idfs ENERGYPLUS_EXAMPLES_DIR ${ENERGYPLUS_EXAMPLES_DIR}/*.idf )
