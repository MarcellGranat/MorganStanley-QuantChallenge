if (!require(pacman, quietly = TRUE)) install.packages("pacman"); library(pacman)
p_load("magrittr", "tidyverse", "pins", "currr", "tidymodels", "bonsai", "patchwork")
p_load_gh("marcellgranat/granatlib")
p_load_gh("marcellgranat/ggProfessional")

options(currr.folder = ".currr", currr.fill = FALSE)
