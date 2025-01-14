## ----style, echo = FALSE, results = 'asis'--------------------------------------------------------
source("https://bioconductor.org/biocLite.R")
biocLite("inSilicoDb")
biocLite("seq2pathway")
library("seq2pathway")
biocLite("DEXSeq")
library("DEXSeq")

biocLite("org.Hs.eg.db")
biocLite("DESeq2")
biocLite("limma")
biocLite("GenomicAlignments")
biocLite("BiocParallel")
biocLite("Rsamtools")
BiocStyle::markdown()
options(width=100, max.print=1000)
knitr::opts_chunk$set(
    eval=as.logical(Sys.getenv("KNITR_EVAL", "TRUE")),
    cache=as.logical(Sys.getenv("KNITR_CACHE", "TRUE")))

## ----setup, echo=FALSE, messages=FALSE, warnings=FALSE--------------------------------------------
suppressPackageStartupMessages({
    library(DESeq2)
    library(limma)
})

## ----configure-test-------------------------------------------------------------------------------
stopifnot(
    getRversion() >= '3.2' && getRversion() < '3.3',
    BiocInstaller::biocVersion() == "3.2"
)

