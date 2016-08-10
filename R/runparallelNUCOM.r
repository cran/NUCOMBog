#' @title Run parallel NUCOM
#' @description Code to run NUCOMBog parallel on multiple cores.
#'
#' @author JWM Pullens
#' @source The test data can be downloaded from \url{http://jeroenpullens.github.io/NUCOMBog_data/}. And the executable of the model can downloaded from \url{https://github.com/jeroenpullens/source_modelMEE}.
#'
#' @param setup The setup needs to be made before by running the setup_NUCOM function.
#' @param clustertype Clustertype: The model has only been tested on SOCK cluster, which is the set to default.
#' @param numCores Number of Cores on which are model needs to be run (NOTE: Non-parallel runs can only be run on 1 core). Default is 1.
#' @param parameters The parameters which are used in the model. If no parameter values are given the default values will be used. The parameters have to have the format of a dataframe with colum names: "names" and "values", see example \url{https://github.com/jeroenpullens/NUCOMBog_data}. The default parameters are from Heijmans et al. 2008.
#' @param MPI_server set to TRUE if after each iteration the MPI server needs to be destroyed. Default is FALSE
#' @keywords NUCOMBog
#'
#' @references Heijmans, M., Mauquoy, D., van Geel, B., and Berendse, F. (2008). Long-term effects of climate change on vegetation and carbon dynamics in peat bogs. Journal of Vegetation Science, 19(3)
#'
#' @examples
#' \dontrun{
#' !!the variable "test_setup" is from the function setupNUCOM, see the help for more information!!
#'
#' parallel<-runparallelNUCOM(setup = test_setup,
#'                             clustertype = "SOCK",
#'                             numCores = 1,
#'                             parameters=initialParameters)
#' }
#' @export
#' @import snowfall
#' @import utils


runparallelNUCOM<-function(setup,clustertype,numCores=1,parameters,MPI_server=F){
  # startval <- setup$runParameters[[1]]$startval

  setwd(setup$runParameters[[1]]$mainDir)
  #we need to make the structure in all the folders
  runParameters<-setup$runParameters

  runParameters<-combine_setup_parameters(runParameters = runParameters,parameters = parameters)

    pb <- txtProgressBar(min = 0, max = length(runParameters), style = 3)
  print("Making Folder Structure")
  for (i in 1:length(runParameters)){
    setTxtProgressBar(pb, i)
    # copy files and folders:
    clim<-readLines(con=paste("input/",runParameters[[i]]$climate,sep=""))
    env<-readLines(con=paste("input/",runParameters[[i]]$environment,sep=""))
    ini<-readLines(con=paste("input/",runParameters[[i]]$inival,sep=""))

    filepath<-paste("folder",i,sep="")
    dir.create(filepath,showWarnings = F)

    # input folder with inival,clim,environm (these files do not change)
    dir.create(paste(filepath,"/input",sep=""),showWarnings = F)
    dir.create(paste(filepath,"/output",sep=""),showWarnings = F)
    writeLines(clim,paste(filepath,"/input/",runParameters[[i]]$climate,sep=""))
    writeLines(env,paste(filepath,"/input/",runParameters[[i]]$environment,sep=""))
    writeLines(ini,paste(filepath,"/input/",runParameters[[i]]$inival,sep=""))

    if(.Platform$OS.type=="unix"){
      file.copy(from = "modelMEE",to = paste(filepath,"/",sep="") )}
      if(.Platform$OS.type=="windows"){
        file.copy(from = "modelMEE.exe",to = paste(filepath,"/",sep="") )}
    }
      close(pb)
      print("Folder Structure Made")
      # then run nucom which creates the "param.txt","Filenames"

      # Create cluster
      print('Create cluster')
      if (clustertype =="SOCK"){
        snowfall::sfInit(parallel=TRUE, cpus=numCores, type="SOCK")
        # Exporting needed data and loading required packages on workers
        snowfall::sfLibrary("NUCOMBog",character.only = TRUE)
        snowfall::sfExport("setup","runParameters")

        # Distribute calculation: will return values as a list object
        cat ("Sending tasks to the cores\n")
        result =  snowfall::sfSapply(runParameters,runnucom_wrapper)

        # Destroy cluster
        snowfall::sfStop()

      } else if (clustertype =="MPI"){

        # Use Rmpi to spawn and close the slaves
        # Broadcast the data to the slaves and
        # Using own MPISapply with mpi.parsSapply. mpi.parSapply takes a list
        # "cores", so that there is one task for each core.
        # Then each core is aware of how many task he has to carry and applies
        # MPISapply on its tasks. Result is a list of list, thus, it must be
        # unlisted
        # needlog avoids fork call
        if(is.loaded ("mpi_initialize")){
          if (Rmpi::mpi.comm.size() < 1 ){
            cat( paste ("\nCreating a", clustertype, "cluster with",
                        numCores, "cores", sep = " " ))
            cat("\nPlease call exit_mpi at the end of you script")
            Rmpi::mpi.spawn.Rslaves(nslaves = numCores, needlog = FALSE)
          }else{
            cat(paste("\nUsing the existing", clustertype, "cluster with",
                      numCores, " cores", sep = " " ))
          }
        }
        cores <- rep(numCores, numCores)
        Rmpi::mpi.bcast.Robj2slave(cores)
        Rmpi::mpi.bcast.Robj2slave(runParameters)
        Rmpi::mpi.bcast.Robj2slave(setup)
        Rmpi::mpi.bcast.Robj2slave(library(NUCOMBog))

        result <- Rmpi::mpi.parSapply(cores, MPISapply, runParameters = runParameters)
      }
      if(clustertype =="MPI"){
        # result<-unlist(result,recursive = F)
        attributes(result)<-list(dim=c(length(runParameters[[1]]$type)+2,(length(setup$runParameters))),dimnames=list(c("year","month",runParameters[[1]]$type)))
        if(MPI_server==TRUE){
          Rmpi::mpi.quit()
        }
      }
      return(result)
    }

