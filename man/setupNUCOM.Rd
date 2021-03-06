% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setupNUCOM.r
\name{setupNUCOM}
\alias{setupNUCOM}
\title{make setupNUCOM}
\source{
The executable and the source code of the model can downloaded from \url{https://github.com/jeroenpullens/NUCOMBog}.
}
\usage{
setupNUCOM(mainDir, climate, environment, inival, start, end, type,
  numFolders = 1, parallel = F, separate = F, startval = 1)
}
\arguments{
\item{mainDir}{Working directory}

\item{climate}{climate input (monthly) format: year, month, air temperature, precipitation, potential evapotranspiration (tab seperated). The potential evapotranspiration needs to be calcluated by using the Penman open water evapotranspiration.}

\item{environment}{environment input (yearly) format: year, atmospheric co2 values, nitrogen deposition}

\item{inival}{initial values of biomass}

\item{start}{year in which the simulation starts}

\item{end}{year in which the simulation ends}

\item{type}{Which output is needed? For more information see the help of the getData function.}

\item{numFolders}{The amount of folders that needs to be created (in case of parallel computing)}

\item{parallel}{Run the model on parallel cores? TRUE/FALSE, default is FALSE.}

\item{separate}{Does the model needs to be run for all parameters seperate? Default is FALSE}

\item{startval}{From which row does the output need to be loaded. Default is 1.}
}
\value{
A list with paths and filenames and parameter values which can be implemented in the runnucom and the runnucomParallel function.
}
\description{
Code to make the setup structure needed run the model.

The data used in the example is stored in the package and can be copied to a user specified location via the copytestdata function of this package.
}
\examples{
\dontrun{
#Define complete file path in setup
for LINUX: ~/home/...../data/ ! pay attention to the last "/"
for Windows_ C://..//data// ! pay attention to the last "//"

##Single core setup:
test_setup_singlecore <- setupNUCOM(mainDir="/home/jeroen/NUCOMBog_data/",
                                     climate="ClimLVMhis.txt",
                                     environment="EnvLVMhis.txt",
                                     inival="inivalLVMhis.txt",
                                     start=1766,
                                     end=1999,
                                     type=c("NEE","WTD"),
                                     parallel=F)

## Multi core setup:
names<-c("CO2ref","gram_Beta","eric_MaxGr")

nparvector<-50
initialParameters <- matrix(runif(n=length(names)*nparvector,
                   min=c(300,0.1,40),
                   max=c(500,1,80)),
                   nrow=length(names))
initialParameters<-data.frame(names,initialParameters)
names(initialParameters)<-c("names",rep("values",nparvector))
initialParameters$names<-as.character(initialParameters$names)

test_setup <- setupNUCOM(mainDir="/home/jeroen/NUCOMBog_data/",
                          climate="ClimLVMhis.txt",
                          environment="EnvLVMhis.txt",
                          inival="inivalLVMhis.txt",
                          start=1766,
                          end=1999,
                          type=c("NEE","WTD"),
                          parallel=T,
                          numFolders=nparvector,
                          separate=F,
                          startval=1)

}
}
\author{
JWM Pullens
}
\keyword{NUCOMBog}

