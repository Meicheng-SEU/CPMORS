rm(list=ls())
library("knitr")
library("dplyr")
library("ggplot2")
library("gridExtra")
source("functions.R")

## Original Data
df_test <- read.csv(file = file.path('Data', 'Demo', 'testset.csv'))
df_calib <- read.csv(file = file.path('Data', 'Demo', 'calibset.csv'))
write_output <- TRUE

# Generate Variables: Test-Data / Calibration-Set / Outcome
data <- generate_vars(outcome = "CX", testdata = "test")
testSet <- data$testSet
testLabels <- data$testLabels
calibset <- data$df_calib
col_outcome <- data$col_outcome

pValues_cx <- ICPClassification(testSet = testSet, calibSet = calibset)
efficiency <- CPEfficiency(pValues_cx, testLabels, sigfLevel = 0.05)

# Calibration Plot
cx <- calib_plot(pValues_cx, testSet = testSet) + ggtitle("Test: CX")
# Compute conformal prediction regions at different significance levels
df_pred01 <- df_predict_region(pValues_cx, sigfLevel = .01, outcome = 'CX')
df_pred05 <- df_predict_region(pValues_cx, sigfLevel = .05, outcome = 'CX')
df_pred1 <- df_predict_region(pValues_cx, sigfLevel = .1, outcome = 'CX')
df_pred15 <- df_predict_region(pValues_cx, sigfLevel = .15, outcome = 'CX')

tab01 <- tab_predict_region(df_pred01)
tab05 <- tab_predict_region(df_pred05)
tab1 <- tab_predict_region(df_pred1)
tab15 <- tab_predict_region(df_pred15)
if (write_output){
  write.table(tab01, file = file.path('./All/Output', 'Tables', 'test_CX.csv'))
  write.table(tab05, file = file.path('./All/Output', 'Tables', 'test_CX.csv'), append = TRUE)
  write.table(tab1, file = file.path('./All/Output', 'Tables', 'test_CX.csv'), append = TRUE)

  write.table(df_pred05, file = file.path('./All/Output', 'Tables', 'df_pred05.csv'), sep=',', row.names = FALSE)
  write.table(pValues_cx, file = file.path('./All/Output', 'Tables', 'pValues_cx.csv'), sep=',', row.names = FALSE)
  
  cx <- cx + theme(text = element_text(size = 17))
  cx <- cx + ggtitle("")
  ggsave(filename = file.path('./All/Output', 'Figures', 'cx_test.png'), cx,
         width = 6,
         height = 6)
}
print('sigfLevel = .01')
tab01;
print('sigfLevel = .05')
tab05;
print('sigfLevel = .1')
tab1;
print('sigfLevel = .15')
tab15
grid.arrange(cx, ncol = 1)



########################################################################################
# External validation
########################################################################################
rm(list=ls())
library("knitr")
library("dplyr")
library("ggplot2")
library("gridExtra")
source("functions.R")

## Original Data
df_test <- read.csv(file = file.path('Data', 'Demo', 'externalset.csv'))
df_calib <- read.csv(file = file.path('Data', 'Demo', 'calibset.csv'))

write_output <- TRUE

# Generate Variables: Test-Data / Calibration-Set / Outcome
data <- generate_vars(outcome = "CX", testdata = "test")
testSet <- data$testSet
testLabels <- data$testLabels
calibset <- data$df_calib
col_outcome <- data$col_outcome

pValues_cx <- ICPClassification(testSet = testSet, calibSet = calibset)
efficiency <- CPEfficiency(pValues_cx, testLabels, sigfLevel = 0.05)

# Calibration Plot
cx <- calib_plot(pValues_cx, testSet = testSet) + ggtitle("Test: CX")
stack <- area(pValues_cx, lower=0, upper=1)
# Compute conformal prediction regions at different significance levels
df_pred01 <- df_predict_region(pValues_cx, sigfLevel = .01, outcome = 'CX')
df_pred05 <- df_predict_region(pValues_cx, sigfLevel = .05, outcome = 'CX')
df_pred1 <- df_predict_region(pValues_cx, sigfLevel = .1, outcome = 'CX')
df_pred15 <- df_predict_region(pValues_cx, sigfLevel = .15, outcome = 'CX')

tab01 <- tab_predict_region(df_pred01)
tab05 <- tab_predict_region(df_pred05)
tab1 <- tab_predict_region(df_pred1)
tab15 <- tab_predict_region(df_pred15)
if (write_output){
  write.table(tab01, file = file.path('./All/External_output', 'Tables', 'test_CX.csv'))
  write.table(tab05, file = file.path('./All/External_output', 'Tables', 'test_CX.csv'), append = TRUE)
  write.table(tab1, file = file.path('./All/External_output', 'Tables', 'test_CX.csv'), append = TRUE)

  write.table(df_pred05, file = file.path('./All/External_output', 'Tables', 'df_pred05.csv'), sep=',', row.names = FALSE)

  write.table(pValues_cx, file = file.path('./All/External_output', 'Tables', 'pValues_cx.csv'), sep=',', row.names = FALSE)
  
  cx <- cx + theme(text = element_text(size = 17))
  cx <- cx + ggtitle("")
  ggsave(filename = file.path('./All/External_output', 'Figures', 'cx_test.png'), cx,
         width = 6,
         height = 6)
}
print('sigfLevel = .01')
tab01
print('sigfLevel = .05')
tab05
print('sigfLevel = .1')
tab1
print('sigfLevel = .15')
tab15
grid.arrange(cx, ncol = 1)
