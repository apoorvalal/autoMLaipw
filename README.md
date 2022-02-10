# Tuning-Free AIPW with autoML

h2o runs ML algorithms using a java execultable that can be downloaded
from [here](https://h2o.ai/resources/download/). Setup is seamless on
linux; YMMV.


## demo

Init h2o cluster

```R
library(LalRUtils)
libreq(h2o, data.table, ggplot2)
theme_set(lal_plot_theme())
options("h2o.use.data.table"=TRUE)
# initialise local h2o cluster
h2o.init()

# function to fit outcome and pscore model
source("R/functions.R")

```

```
R is connected to the H2O cluster: 
    H2O cluster timezone:       America/Los_Angeles 
    H2O data parsing timezone:  UTC 
    H2O cluster version:        3.36.0.2 
    H2O cluster version age:    14 days, 21 hours and 54 minutes  
    H2O cluster name:           H2O_started_from_R_alal_fry857 
    H2O cluster total nodes:    1 
    H2O cluster total memory:   5.57 GB 
    H2O cluster total cores:    8 
    H2O cluster allowed cores:  8 
    H2O cluster healthy:        TRUE 
    H2O Connection ip:          localhost 
    H2O Connection port:        54321 
    H2O Connection proxy:       NA 
    H2O Internal Security:      FALSE 
    H2O API Extensions:         Amazon S3, XGBoost, Algos, Infogram, AutoML, Core V3, TargetEncoder, Core V4 
    R Version:                  R version 4.1.1 (2021-08-10) 
```


## fit on lalonde experimental dataset

```R
data(lalonde.exp)
df = setDT(lalonde.exp)
y = 're78'; w = "treat"; x = setdiff(names(df), c(y, w))


outdat = aipw_automl(df, y, w, x)
# expect 9 progress bars - 3 models X (2 prep + 1 fitting)
outdat  %>% str

Classes ‘data.table’ and 'data.frame':  445 obs. of  5 variables:
 $ ehat  : num  0.395 0.293 0.45 0.339 0.354 ...
 $ mu1hat: num  6554 6339 6947 6654 6143 ...
 $ mu0hat: num  4124 4854 4011 4982 4177 ...
 $ w     : int  1 1 1 1 1 1 1 1 1 1 ...
 $ y     : num  9930 3596 24910 7506 290 ...
 - attr(*, ".internal.selfref")=<externalptr> 
```

```R
outdat  %>% ate_estim
[1] 1995 2125 1618

# unbiased since this is an experiment
outdat[, mean(y), w][, V1[1] - V1[2]]
[1] 1794
```

AIPW is closest to the experimental benchmark.


```R
h2o.shutdown(prompt = F)
```
