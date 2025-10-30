ds1<-read.csv("C:/Users/jjsmi/Downloads/My Future/new stuff/Stat Programming/Clinical Trial Analysis/ACUPVIS.csv")
library(table1)

label(ds1$pk1) = "headache score at baseline"
label(ds1$pf1) = "SF36 physical functioning at baseline"
label(ds1$painmedspk1) = "number of pain medications at baseline"
head(ds1)


#Creating table
table1(~sex + age + chronicity + pk1 + pf1 + painmedspk1 + migraine|group, data = ds1,
render.continuous = c("Mean (SD)" = "MEAN (SD)", "Median (IQR)" = "MEDIAN (IQR)"),
digits=4, caption = "Table 1. Study Population Charactersitics")

#Creating table
table1(~group+sex + age + chronicity + pk1 + pf1 + painmedspk1 + migraine|outcome, data = ds1,
       render.continuous = c("Mean (SD)" = "MEAN (SD)", "Median (IQR)" = "MEDIAN (IQR)"),
       digits=4, caption = "Table 2. Comparing Characteristics of Those With Missing vs Not Missing Outcome Data")
