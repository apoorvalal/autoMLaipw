#!/usr/bin/env Rscript
library(LalRUtils)
libreq(h2o, data.table, ggplot2)
theme_set(lal_plot_theme())
options("h2o.use.data.table"=TRUE)
h2o.init()

source("R/functions.R")
# %%
data(lalonde.exp)
df = setDT(lalonde.exp)
y = 're78'; w = "treat"; x = setdiff(names(df), c(y, w))

# %%
outdat = aipw_automl(df, y, w, x)
outdat  %>% ate_estim

# %% Ladd-Lenz (2014) data
ll = fread("LaddLenz.csv")
y = 'vote_l_97'; w = 'tolabor'
x = setdiff(names(ll), c(y, w))

# %%
outdat = aipw_automl(ll, y, w, x)
outdat  %>% ate_estim
# %%

h2o.shutdown(prompt = F)
# %%
