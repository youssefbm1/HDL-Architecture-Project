# Script de Synthèse en langage Tcl.
set project $env(PROJECT)

load_package flow
load_package incremental_compilation
load_package project
project_open $project


# Run initial compilation

execute_module -tool map -args "--incremental_compilation=full_incremental_compilation"
execute_module -tool cdb -args "--merge"
execute_module -tool fit 
execute_module -tool asm
execute_module -tool sta -args "--multicorner=off"

project_close

