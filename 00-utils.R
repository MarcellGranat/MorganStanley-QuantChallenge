if (!require(pacman, quietly = TRUE)) install.packages("pacman"); library(pacman)
p_load("tidyverse", "pins", "currr", "tidymodels")
p_load_gh("marcellgranat/granatlib")
p_load_gh("marcellgranat/ggProfessional")

options(currr.folder = ".currr", currr.fill = FALSE)

theme_set(theme_gR())
