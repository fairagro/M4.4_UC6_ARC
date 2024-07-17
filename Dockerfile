FROM rocker/r-ver:4.4

RUN apt-get update && apt-get install -y git sudo wget

RUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh

RUN chmod +x ./install_requirements.sh && ./install_requirements.sh

RUN R -e 'install.packages("devtools")'
RUN R -e 'install.packages("optparse")'
RUN R -e 'devtools::install_github("AgMIP-GGCMI/cropCalendars")'
RUN R -e 'devtools::install_github("fairagro/uc6_csmTools@feature/package_management")'